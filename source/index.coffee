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
		fringeColor: 'lightgray'

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
						fill: if grayCodeTable[index][position] % 2 is 0 \
							then foregroundColor
							else backgroundColor
					}

				# Merge adjacent sections with same color
				.reduce (sections, currentSection, sectionIndex) ->

					if (sections[sections.length - 1] and \
					sections[sections.length - 1].fill is \
					currentSection.fill)

						sections[sections.length - 1].endAngle = \
							currentSection.endAngle
					else
						sections.push currentSection

					# Also merge last and first section
					if sectionIndex is numberOfSections - 1 and \
					sections[sections.length - 1].fill is sections[0].fill
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
						style: {fill: section.fill}
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
			{
				transform: "translate(#{discDiameter/2},#{discDiameter/2})"
				'clip-path': 'url(#discWithAxleHole)'
			}
			['circle', {
				r: discDiameter/2
				fill: fringeColor
			}]
			# The track discs - one for each bit position
			discs...
			['circle', {
				r: axleMargin + axleDiameter/2
				fill: fringeColor
			}]
		]
	]
