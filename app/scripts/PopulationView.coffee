textSize = 16

class @PopulationView
    constructor: (@game, @population, heading, x) ->
        @texts = []
        style = { font: "#{textSize}px Arial", fill: '#8800ff' }
        y = @game.height - textSize

        for i in [0...@population.numberOfAges]
            c = @population.getPopulationForAge(i)
            @texts[i] = @game.add.text(x, y, "#{c}", style)
            @texts[i].fixedToCamera = true
            y -= textSize

        text = @game.add.text(x, y, heading, style)
        text.fixedToCamera = true

    update: ->
        for i in [0...@population.numberOfAges]
            c = @population.getPopulationForAge(i)
            @texts[i].text = c
