textSize = 16
lineDistance = 16
lineThickness = 6

pyramidScale = 400 / 60000

class @PopulationView
    constructor: (@game, @population, heading, x, @colors, @right) ->
        @texts = []
        style = { font: "#{textSize}px Arial", fill: '#8800ff' }
        y = @game.height - textSize * 2

        for i in [0...@population.numberOfAges]
            c = @population.getPopulationForAge(i)
            @texts[i] = @game.add.text(x, y, "#{c}", style)
            @texts[i].fixedToCamera = true
            y -= textSize

        text = @game.add.text(x, y, heading, style)
        text.fixedToCamera = true

        @graphics = @game.add.graphics(0, 0)
        @graphics.fixedToCamera = true

    update: ->
        for i in [0...@population.numberOfAges]
            c = @population.getPopulationForAge(i)
            @texts[i].text = c

        @graphics.clear()
        @graphics.lineStyle(lineThickness, @colors.bar, .3)
        for i in [0...@population.numberOfAges]
            c = @population.getPopulationForAge(i)
            if c == 0
                continue
            width = c * pyramidScale
            y = @game.height - 32 - i * lineDistance
            if @right
                @graphics.moveTo(@game.width - 5 - width, y)
                @graphics.lineTo(@game.width - 5, y)
            else
                @graphics.moveTo(5, y)
                @graphics.lineTo(c * pyramidScale, y)

