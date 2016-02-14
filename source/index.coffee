grayCode = require 'gray-code'

module.exports.shaven = (config, tools) ->

	defaults =
		# Resolution
		bits: 8

		# Dimenstions
		diskDiameter: 100
		# or
		trackWidth: null
		trackMargin: 0

		axleDiameter: 20
		axleOffset: 0
		padding: 0

	{
		diskDiameter
		bits
		trackWidth
		trackMargin
		axleDiameter
		axleOffset
		padding
	} = Object.assign({}, defaults, config)

	grayCodeTable = grayCode bits
	numberOfSections = Math.pow(2, bits)
	tracksWidth = if trackWidth \
		then (trackWidth + trackMargin) * bits
		else diskDiameter/2 - axleDiameter/2


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
							(
								(position + 1) *
								((diskDiameter - axleDiameter) / (bits * 2))
							)

						startAngle: sectionAngle * index
						endAngle: sectionAngle * (index + 1)
						fill: if grayCodeTable[index][position] % 2 is 0 \
							then 'white'
							else 'black'
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
		width: diskDiameter + 'mm'
		height: diskDiameter + 'mm'
		viewBox: [
			0
			0
			diskDiameter
			diskDiameter
		]
		['defs',
			['clipPath#discWithAxleHole'
				{
					transform: [{
						type: 'translate'
						x: -diskDiameter/2
						y: -diskDiameter/2
					}]
				}
				['path', {
					d: "M0,0
						h#{diskDiameter}
						v#{diskDiameter}
						h#{-diskDiameter}
						z
						M#{tracksWidth},#{diskDiameter/2}
						a 1,1 0 0 0 #{axleDiameter},0
						a 1,1 0 0 0 #{-axleDiameter},0
						z"
				}]
			]
		]
		['g'
			{
				transform: 'translate(50,50)'
				'clip-path': 'url(#discWithAxleHole)'
			}
			# The discs - one for each bit position
			discs...
		]
	]
