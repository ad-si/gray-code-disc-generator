import shaven from "shaven"
import grayCode from "gray-code"
import CircleSector from "circle-sector"

function binaryCodeTable(bits: number) {
  new Array(Math.pow(2, bits)).fill(0).map((_value, index) => {
    return (new Array(bits).fill(0).join("") + index.toString(2))
      .slice(-bits)
      .split("")
  })
}

function getShavenArray({
  bits = 8,

  // Dimenstions
  discDiameter = 120,
  // or
  trackWidth = 0,
  trackMargin = 0,

  axleDiameter = 13,
  axleMargin = 5,
  discPadding = 5,
  backgroundColor = "black",
  foregroundColor = "white",
  fringeColor = "gray",
  strokeColor = "rgb(255, 0, 0)",
  strokeWidth = 0.1,
  isLasercutterView = false,
  printAngleLabels = true,
  code = "gray", // gray
}: {
  bits?: number
  discDiameter?: number
  trackWidth?: number
  trackMargin?: number
  axleDiameter?: number
  axleMargin?: number
  discPadding?: number
  backgroundColor?: string
  foregroundColor?: string
  fringeColor?: string
  strokeColor?: string
  strokeWidth?: number
  isLasercutterView?: boolean
  printAngleLabels?: boolean
  code?: string
}) {
  const grayCodeTable = code === "gray" ? grayCode(bits) : binaryCodeTable(bits)
  const numberOfSections = Math.pow(2, bits)
  const tracksWidth = trackWidth
    ? (trackWidth + trackMargin) * bits
    : discDiameter / 2 - axleDiameter / 2 - axleMargin - discPadding

  if (!trackWidth) {
    trackWidth = tracksWidth / bits
  }

  const discs = new Array(bits)
    .fill(0)
    .map(function (_disc, position) {
      const magnitude = Math.pow(2, position + 1)

      return (
        new Array(numberOfSections)
          .fill(0)
          .map(function (value, index, codes) {
            const sectionAngle = 360 / numberOfSections

            return {
              radius:
                axleDiameter / 2 + axleMargin + (position + 1) * trackWidth,

              startAngleInDeg: sectionAngle * index,
              endAngleInDeg: sectionAngle * (index + 1),
              class:
                grayCodeTable[index][position] % 2 === 0
                  ? "foreground"
                  : "background",
            }
          })

          // Merge adjacent sections with same color
          .reduce(function (sections, currentSection, sectionIndex) {
            if (
              sections[sections.length - 1] &&
              sections[sections.length - 1].class === currentSection.class
            ) {
              sections[sections.length - 1].endAngleInDeg =
                currentSection.endAngleInDeg
            } else {
              sections.push(currentSection)
            }

            // Also merge last and first section
            if (
              sectionIndex === numberOfSections - 1 &&
              sections[sections.length - 1].class === sections[0].class
            ) {
              // Merge last section into first section
              sections[0].startAngleInDeg =
                sections[sections.length - 1].startAngleInDeg
              // Remove last section
              sections.pop()
            }

            return sections
          }, [])

          .map(function (section, sectionIndex) {
            const circleSector = new CircleSector(section)
            section.pathString = circleSector.svgPath
            return section
          })
          .map((section, index) => [
            "path",
            {
              d: section.pathString,
              class: section.class + (isLasercutterView ? " lasercut" : ""),
            },
          ])
      )
    })

    .map((sections) => ["g", ...Array.from(sections)])
    .reverse()

  const labels = new Array(numberOfSections)
    .fill()
    .map(function (value, index) {
      const angleInDeg = (360 / numberOfSections) * index
      const angleInRad = (Math.PI / numberOfSections) * index
      return [
        "text",
        String(angleInDeg),
        {
          x: tracksWidth * Math.cos(angleInRad),
          y: tracksWidth * Math.sin(angleInRad),
        },
      ]
    })

  return [
    "svg",
    {
      width: discDiameter + "mm",
      height: discDiameter + "mm",
      viewBox: [0, 0, discDiameter, discDiameter],
    },
    [
      "style",
      `\
.foreground {
	fill: ${foregroundColor};
}
.background {
	fill: ${backgroundColor};
}
.fringe {
	fill: ${fringeColor};
}
.lasercut {
	fill: none !important;
	stroke: ${strokeColor} !important;
	stroke-width: ${strokeWidth} !important;
}\
`,
    ],
    [
      "defs",
      [
        "clipPath#discWithAxleHole",
        {
          transform: [
            {
              type: "translate",
              x: -discDiameter / 2,
              y: -discDiameter / 2,
            },
          ],
        },
        [
          "path",
          {
            d: `M0,0 \
h${discDiameter} \
v${discDiameter} \
h${-discDiameter} \
z \
M${discPadding + tracksWidth + axleMargin}, \
${discDiameter / 2} \
a 1,1 0 0 0 ${axleDiameter},0 \
a 1,1 0 0 0 ${-axleDiameter},0 \
z`,
          },
        ],
      ],
    ],
    [
      "g.discs",
      {
        fill: "transparent",
        transform: `translate(${discDiameter / 2},${discDiameter / 2})`,
        "clip-path": "url(#discWithAxleHole)",
      },

      [
        "circle",
        {
          class: isLasercutterView ? "lasercut" : "fringe",
          r: discDiameter / 2,
          style: {
            fill: !isLasercutterView ? fringeColor : undefined,
            stroke: isLasercutterView ? strokeColor : undefined,
            "stroke-width": strokeWidth,
          },
        },
      ],

      // The track discs - one for each bit position
      ...Array.from(discs),

      [
        "circle.fringe",
        { r: axleMargin + axleDiameter / 2 },
        !isLasercutterView,
      ],
      ["circle.lasercut", { r: axleDiameter / 2 }, isLasercutterView],
    ],
    // ['g.labels'
    // 	labels...
    // 	printAngleLabels
    // ]
  ]
}

export function generateDiscSVG({ resolution = 8 }: { resolution?: number }) {
  return shaven(getShavenArray({ bits: resolution })).rootElement.replace(
    "<svg",
    '<svg xmlns="http://www.w3.org/2000/svg" ' +
      'xmlns:xlink="http://www.w3.org/1999/xlink"'
  )
}
