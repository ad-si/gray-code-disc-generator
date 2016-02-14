grayCode = require 'gray-code'

module.exports.shaven = (config, tools) ->

	defaults =
		# Resolution
		bits: 8

		# Dimenstions
		discDiameter: 120
		# or
		trackWidth: null
		trackMargin: 0

		axleDiameter: 13
		axleMargin: 5
		discPadding: 5
		backgroundColor: 'black'
		foregroundColor: 'white'
		fringeColor: 'gray'
		strokeColor: tools.rgb(255,0,0)
		strokeWidth: 0.1
		isLasercutterView: false

	{
		discDiameter
		bits
		trackWidth
		trackMargin
		axleDiameter
		axleMargin
		discPadding
		backgroundColor
		foregroundColor
		fringeColor
		strokeColor
		strokeWidth
		isLasercutterView
	} = Object.assign({}, defaults, config)

	grayCodeTable = grayCode bits
	numberOfSections = Math.pow(2, bits)
	tracksWidth = if trackWidth \
		then (trackWidth + trackMargin) * bits
		else discDiameter/2 - axleDiameter/2 - axleMargin - discPadding

	if not trackWidth
		trackWidth = tracksWidth / bits


	discs = new Array bits
		.fill()
		.map (disc, position) ->
			magnitude = Math.pow(2, (position + 1))

			return new Array numberOfSections
				.fill(0)
				.map (value, index, codes) ->
					sectionAngle = 360 / numberOfSections

					return {
						radius: (axleDiameter/2) +
							axleMargin +
							((position + 1) * trackWidth)

						startAngle: sectionAngle * index
						endAngle: sectionAngle * (index + 1)
						class: if grayCodeTable[index][position] % 2 is 0 \
							then 'foreground'
							else 'background'
					}

				# Merge adjacent sections with same color
				.reduce (sections, currentSection, sectionIndex) ->

					if (sections[sections.length - 1] and \
					sections[sections.length - 1].class is \
					currentSection.class)

						sections[sections.length - 1].endAngle = \
							currentSection.endAngle
					else
						sections.push currentSection

					# Also merge last and first section
					if sectionIndex is numberOfSections - 1 and \
					sections[sections.length - 1].class is sections[0].class
						# Merge last section into first section
						sections[0].startAngle = \
							sections[sections.length - 1].startAngle
						# Remove last section
						sections.pop()

					return sections
				,[]

				.map (section, sectionIndex) ->
					section.pathString = tools.circleSection section
					return section

				.map (section, index) ->['path', {
						d: section.pathString,
						class: section.class + ' ' +
							if isLasercutterView then 'lasercut'
					}]

		.map (sections) ->
			return ['g', sections...]
		.reverse()

	return [
		'svg'
		width: discDiameter + 'mm'
		height: discDiameter + 'mm'
		viewBox: [
			0
			0
			discDiameter
			discDiameter
		]
		['style',
			"""
			.foreground {
				fill: #{foregroundColor};
			}
			.background {
				fill: #{backgroundColor};
			}
			.fringe {
				fill: #{fringeColor};
			}
			.lasercut {
				fill: none !important;
				stroke: #{strokeColor} !important;
				stroke-width: #{strokeWidth} !important;
			}
			"""
		]
		['defs',
			['clipPath#discWithAxleHole'
				{
					transform: [{
						type: 'translate'
						x: -discDiameter/2
						y: -discDiameter/2
					}]
				}
				['path', {
					d: "M0,0
						h#{discDiameter}
						v#{discDiameter}
						h#{-discDiameter}
						z
						M#{discPadding + tracksWidth + axleMargin},
							#{discDiameter/2}
						a 1,1 0 0 0 #{axleDiameter},0
						a 1,1 0 0 0 #{-axleDiameter},0
						z"
				}]
			]
		]
		['g'
			fill: 'transparent'
			transform: "translate(#{discDiameter/2},#{discDiameter/2})"
			'clip-path': 'url(#discWithAxleHole)'

			['circle', {
				class: if isLasercutterView then 'lasercut' else 'fringe'
				r: discDiameter/2
				style:
					fill: if not isLasercutterView then fringeColor
					stroke: if isLasercutterView then strokeColor
					'stroke-width': strokeWidth

			}]

			# The track discs - one for each bit position
			discs...

			['circle.fringe'
				r: axleMargin + axleDiameter/2
				not isLasercutterView
			]
			['circle.lasercut'
				r: axleDiameter/2
				isLasercutterView
			]
		]
	]
