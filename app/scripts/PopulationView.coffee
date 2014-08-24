textSize = 16
lineDistance = 16
lineThickness = 6

pyramidScale = 400 / 60000

debug = false

class @PopulationView
    constructor: (@game, @population, @secondary, heading, x, @colors, @right) ->
        if debug
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

        @primaryWidths = (0 for i in [0...@population.numberOfAges])

    getYForBar: (age) ->
         @game.height - 32 - age * lineDistance

    update: ->
        for i in [0...@population.numberOfAges]
            c = @population.getPopulationForAge(i)
            if debug
                @texts[i].text = c
            width = c * pyramidScale
            @primaryWidths[i] = width

        @graphics.clear()
        @graphics.lineStyle(lineThickness, @colors.barUnderage, .3)
        for i in [0...@population.numberOfAges]
            if i == @population.fertilityAge
                @graphics.lineStyle(lineThickness, @colors.bar, .3)
            width = @primaryWidths[i]
            if width == 0
                continue
            y = @getYForBar(i)
            if @right
                @graphics.moveTo(@game.width - 5 - width, y)
                @graphics.lineTo(@game.width - 5, y)
            else
                @graphics.moveTo(5, y)
                @graphics.lineTo(width + 5, y)

        if @secondary
            @graphics.lineStyle(lineThickness, @colors.secondaryBar, .3)
            for i in [0...@secondary.numberOfAges]
                width = @secondary.getPopulationForAge(i) * pyramidScale
                if width == 0
                    continue
                y = @getYForBar(i)
                @graphics.moveTo(5 + @primaryWidths[i], y)
                @graphics.lineTo(5 + @primaryWidths[i] + width, y)
