class @PopulationView
    constructor: (@game, @population) ->
        @texts = []
        style = { font: '16px Arial', fill: '#8800ff' }
        y = @game.height - 16
        for i in [0...@population.numberOfAges]
            c = @population.getPopulationForAge(i)
            @texts[i] = @game.add.text(0, y, "#{c}", style)
            @texts[i].fixedToCamera = true
            y -= 18

        text = @game.add.text(0, y, 'Population', style)
        text.fixedToCamera = true

    update: ->
        for i in [0...@population.numberOfAges]
            c = @population.getPopulationForAge(i)
            @texts[i].text = c
