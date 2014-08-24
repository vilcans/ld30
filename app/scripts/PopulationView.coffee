textSize = 7

class @PopulationView
    constructor: (@game, @population, x) ->
        @texts = []
        style = { font: "#{textSize}px Arial", fill: '#8800ff' }
        y = @game.height - textSize

        @projectilesText = @game.add.text(x + 70, y, "#{@population.projectiles}", style)
        @projectilesText.fixedToCamera = true

        for i in [0...@population.numberOfAges]
            c = @population.getPopulationForAge(i)
            @texts[i] = @game.add.text(x, y, "#{c}", style)
            @texts[i].fixedToCamera = true
            y -= textSize

        text = @game.add.text(x, y, 'Population', style)
        text.fixedToCamera = true

    update: ->
        for i in [0...@population.numberOfAges]
            c = @population.getPopulationForAge(i)
            @texts[i].text = c
        @projectilesText.text = "h #{@population.projectiles}"
