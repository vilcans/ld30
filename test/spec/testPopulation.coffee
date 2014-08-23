describe 'Population', ->
    pop = new Population
    it 'has an age pyramid', ->
        assert.equal pop.getPopulationForAge(0), 1000
        assert.equal pop.getPopulationForAge(1), 900
        assert.equal pop.getPopulationForAge(2), 800

    it 'advances to next group for each year', ->
        pop.advanceYear()
        assert.equal pop.getPopulationForAge(0), 0
        assert.equal pop.getPopulationForAge(1), 1000
        assert.equal pop.getPopulationForAge(2), 900
