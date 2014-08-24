describe 'Population', ->
    pop = new Population([
        1000,
        900,
        800,
    ])
    it 'has an age pyramid', ->
        assert.equal pop.getPopulationForAge(0), 1000
        assert.equal pop.getPopulationForAge(1), 900
        assert.equal pop.getPopulationForAge(2), 800

    it 'can calculate fertile population', ->
        assert.equal 900 + 800, pop.getFertilePopulation()

    it 'advances to next group', ->
        pop.increaseAges()
        assert.equal pop.getPopulationForAge(0), 0
        assert.equal pop.getPopulationForAge(1), 1000
        assert.equal pop.getPopulationForAge(2), 900
