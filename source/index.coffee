grayCode = require 'gray-code'

module.exports.shaven = (config, tools) ->

	defaults =
		width: 100
		height: 100
		bits: 8

	{width, height, bits} = Object.assign({}, defaults, config)

	grayCodeTable = grayCode bits
	numberOfSections = Math.pow(2, bits)
	smallestDimenstion = if width > height then width else height


	discs = new Array bits
		.fill()
		.map (disc, position) ->
			magnitude = Math.pow(2, (position + 1))

			return new Array numberOfSections
				.fill(0)
				.map (value, index, codes) ->
					sectionAngle = 360 / numberOfSections

					return {
						radius: (position + 1) * \
							(smallestDimenstion / (bits * 2))
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
		width: width + 'mm'
		height: height + 'mm'
		viewBox: [
			0
			0
			width
			height
		]
		['defs',
			['clipPath#discWithAxleHole'

			]
		]
		['g',
			{
				transform: 'translate(50,50)'
			}
			# The discs - one for each position
			discs...
		]
	]
