class @Population
    constructor: (@agePyramid, @fertilityAge=1, @mortality) ->
        @numberOfAges = @agePyramid.length

    getPopulationForAge: (age) ->
        return @agePyramid[age] or 0

    increaseAges: ->
        for i in [@numberOfAges - 1..1]
            @agePyramid[i] = @agePyramid[i - 1]
        @agePyramid[0] = 0

    addBabies: (count) ->
        @agePyramid[0] += count

    getFertilePopulation: ->
        s = 0
        i = @fertilityAge
        while i < @numberOfAges
            s += @agePyramid[i++]
        return s

    getUnderagePopulation: ->
        s = 0
        i = 0
        while i < @fertilityAge
            s += @agePyramid[i++]
        return s

    getTotal: ->
        s = 0
        for age in @agePyramid
            s += age
        return s

    # Remove the oldest `count` people
    remove: (count) ->
        left = count
        i = @agePyramid.length
        while --i >= 0
            if @agePyramid[i] >= left
                @agePyramid[i] -= left
                return
            left -= @agePyramid[i]
            @agePyramid[i] = 0

    randomKills: ->
        for i in [0...@numberOfAges]
            kills = Math.ceil(@agePyramid[i] * @mortality.percentage + @mortality.absolute)
            @agePyramid[i] -= kills
            if @agePyramid[i] < 0
                @agePyramid[i] = 0
        return
