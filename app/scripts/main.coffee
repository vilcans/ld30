tweaks = {
    yearLength: 10
}

class Planet
    constructor: ({gravity, @diameter, @orbitalPeriod, @orbitalDistance, @launchPeriod, @launchSpeed, @orbitPhase, @population}) ->
        @gravity = gravity or 0
        @radius = @diameter / 2
        @orbitPhase ?= 0
        @radiusE = @radius + 2  # radius plus epsilon (launch radius)
        @radiusSquared = @radius * @radius
        @orbitSpeed = (@orbitalDistance * 2 * Math.PI) / @orbitalPeriod
        @velocity = new Phaser.Point
        @center = new Phaser.Point
        @angularVelocity = Math.PI * 2 / @orbitalPeriod

        @launcherAngle = 0
        @emitting = false

        @selectedWithPointer = null

    setTime: (t) ->
        angle = @angularVelocity * t + @orbitPhase
        sin = Math.sin(angle)
        cos = Math.cos(angle)
        @sprite.x = @center.x = cos * @orbitalDistance
        @sprite.y = @center.y = -sin * @orbitalDistance
        @velocity.x = -sin * @orbitSpeed
        @velocity.y = -cos * @orbitSpeed
        return

    createSprite: (game) ->
        bmd = game.add.bitmapData(@diameter, @diameter)

        bmd.ctx.fillStyle = '#999999'
        bmd.ctx.beginPath()
        bmd.ctx.arc(@radius, @radius, @radius, 0, Math.PI * 2, true)
        bmd.ctx.closePath()
        bmd.ctx.fill()

        @sprite = game.add.sprite(@center.x, @center.y, bmd)
        @sprite.anchor.set .5, .5

        @sprite.inputEnabled = true

    # Point the launcher at a world coordinate
    setDirection: (x, y) ->
        @launcherAngle = Phaser.Math.angleBetween(@center.x, @center.y, x, y)

    startEmitting: ->
        if @emitting
            return
        @emitter.start(false, 20000, @launchPeriod, 0)
        @emitting = true

    stopEmitting: ->
        if not @emitting
            return
        @emitter.start(false, 0, 1e9)  # stop it
        @emitting = false

    select: (pointer) ->
        @selectedWithPointer = pointer
        @startEmitting()

    deselect: (pointerId) ->
        if not @selectedWithPointer
            return
        if @selectedWithPointer.id != pointerId
            return
        #@selectedSprite.visible = true
        @selectedWithPointer = null
        @stopEmitting()

    isSelected: -> @selectedWithPointerId != null

planetData = [
    # 0 venus
    {
        diameter: 12
        orbitalPeriod: 200
        orbitalDistance: 80
        orbitPhase: .3
        gravity: 1e5
        launchPeriod: 1000
        launchSpeed: 250
        population: new Population
    }
    # 1 mars
    {
        diameter: 15
        orbitalPeriod: 120
        orbitalDistance: 150
        orbitPhase: 0
        gravity: 1e5
        launchPeriod: 20
        launchSpeed: 200
        population: new Population
    }
    # 2 earth
    {
        diameter: 20
        orbitPhase: Math.PI / 2
        orbitalPeriod: tweaks.yearLength
        orbitalDistance: 100
        gravity: 1e5
    }
    # 3 sun
    {
        diameter: 60
        orbitalPeriod: 1
        orbitalDistance: 0
        gravity: 1e6
    }
]
if false
    for i in [1..10]
        planetData.push
            diameter: Math.random() * 25 + 5
            orbitalPeriod: Math.random() * 10 + 1
            orbitalDistance: Math.random() * 90

class GameState
    preload: ->
        @game.load.image('projectile0', 'assets/baby.png')
        @game.load.image('projectile1', 'assets/sperm.png')

    create: ->
        @game.world.setBounds(-1000, -1000, 2000, 2000)
        @game.world.camera.focusOnXY(0, 0)

        @planets = (new Planet(data) for data in planetData)

        for i in [0, 1]
            emitter = @game.add.emitter(0, 0, 1000)
            emitter.gravity = 0
            emitter.makeParticles("projectile#{i}")
            @planets[i].emitter = emitter

        @game.input.onDown.add(
            (pointer, event) ->
                for planet in @planets
                    if planet.emitter and not planet.emitting and planet.sprite.input.pointerOver(pointer.id)
                        console.log 'selecting', planet
                        planet.select(pointer)
                        break
                return
            this
        )
        @game.input.onUp.add(
            (pointer, event) ->
                for planet in @planets
                    planet.deselect(pointer.id)
                return
            this
        )

        for planet in @planets
            planet.createSprite(@game)

        @populationView0 = new PopulationView(@game, @planets[0].population)

        @startTime = @game.time.now  # ms
        @year = 0
        return

    update: ->
        gameTime = (@game.time.now - @startTime) / 1000
        for planet in @planets
            planet.setTime(gameTime)
        newYear = Math.floor(gameTime / tweaks.yearLength)
        if newYear != @year
            @planets[0].population.advanceYear()
            @planets[1].population.advanceYear()
            @year = newYear

        for planet in @planets
            if planet.emitter
                angle = planet.launcherAngle
                sin = Math.sin(angle)
                cos = Math.cos(angle)
                xspeed = cos * planet.launchSpeed + planet.velocity.x
                yspeed = sin * planet.launchSpeed + planet.velocity.y
                planet.emitter.setXSpeed(xspeed, xspeed)
                planet.emitter.setYSpeed(yspeed, yspeed)
                planet.emitter.emitX = planet.center.x + planet.radiusE * cos
                planet.emitter.emitY = planet.center.y + planet.radiusE * sin
                planet.emitter.forEachExists(@updateGravity, this)

            planet.setDirection(@game.input.worldX, @game.input.worldY)

        @populationView0.update()
        return

    updateGravity: (particle) ->
        g = particle.body.gravity
        g.x = g.y = 0
        for planet in @planets
            dx = particle.x - planet.center.x
            dy = particle.y - planet.center.y
            distanceSquared = dx * dx + dy * dy
            if distanceSquared < planet.radiusSquared
                if planet.population
                    planet.population.addBabies(1)
                particle.kill()
                return
            distance = Math.sqrt(distanceSquared)
            dxNorm = dx / distance
            dyNorm = dy / distance
            g.x -= dxNorm * planet.gravity / distanceSquared
            g.y -= dyNorm * planet.gravity / distanceSquared

class MenuState
    preload: ->

    create: ->
        t = @game.add.text(
            @game.width / 2, 0,
            'Welcome to Ludum Dare 30',
            style = { font: '32px Arial', fill: '#8800ff', align: 'center' }
        )
        t.anchor.set(.5, 0)

    update: ->

    render: ->

start = ->
    game = new Phaser.Game(800, 300, Phaser.CANVAS, 'LD30')
    game.state.add('menu', MenuState)
    game.state.add('game', GameState)
    game.state.start('game')

start()
