class @Population
    constructor: ->
        @agePyramid = [
            1000,
            900,
            800,
            700,
            600,
            500,
            400,
            300,
            200,
            100
        ]
        #@mortality = 0
        @numberOfAges = @agePyramid.length

    getPopulationForAge: (age) ->
        return @agePyramid[age] or 0

    advanceYear: ->
        for i in [@agePyramid.length - 1..1]
            @agePyramid[i] = @agePyramid[i - 1] #* (1 - @mortality)
        @agePyramid[0] = 0

    addBabies: (count) ->
        @agePyramid[0] += count
