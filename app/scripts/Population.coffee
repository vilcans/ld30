class @Population
    constructor: (@agePyramid, @fertilityAge=1) ->
        @numberOfAges = @agePyramid.length
        #@mortality = 0
        @projectiles = 0

    getPopulationForAge: (age) ->
        return @agePyramid[age] or 0

    increaseAges: ->
        for i in [@numberOfAges - 1..1]
            @agePyramid[i] = @agePyramid[i - 1] #* (1 - @mortality)
        @agePyramid[0] = 0

    addBabies: (count) ->
        @agePyramid[0] += count

    hasProjectiles: ->
        return @projectiles > 0

    decreaseProjectiles: (amount) ->
        @projectiles = Math.max(0, @projectiles - amount)

    getFertilePopulation: ->
        s = 0
        for i in [@fertilityAge...@numberOfAges]
            s += @agePyramid[i]
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
