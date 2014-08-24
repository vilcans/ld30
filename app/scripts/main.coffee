tweaks = {
    tickLength: 100  # ms
    yearLength: 30
    babiesInProjectile: 25
    babyProbability: .01
    # Number of sperms produced per man per tick
    maleFertility: 1e-3
    maxSpermBank: 1000
}

class ProjectileEmitter extends Phaser.Particles.Arcade.Emitter
    constructor: (@planet, game, maxParticles) ->
        super(game, 0, 0, maxParticles)

    # overrides Emitter
    emitParticle: ->
        if not @planet.canLaunch()
            return
        @planet.onLaunch()
        super()

class Sperm extends Phaser.Particle
    quantity: 1
    receiveByVenus: (venus) ->
        if venus.rnd.frac() < tweaks.babyProbability
            return
        if venus.rnd.frac() < .5
            venus.females.addBabies(1)
        else
            venus.males.addBabies(1)
    receiveByMars: (mars) ->
        # wasted

class Baby extends Phaser.Particle
    quantity: 100
    receiveByVenus: (venus) ->
        # returned to Venus; wasted
    receiveByMars: (mars) ->
        mars.males.addBabies(tweaks.babiesInProjectile)

class Planet
    # for overriding
    particleClass: Phaser.Particle

    constructor: (@id, {gravity, @diameter, @orbitalPeriod, @orbitalDistance, @launchPeriod, @launchSpeed, launchJitter, @orbitPhase, @color}) ->
        @launchJitter = launchJitter or 0
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

        bmd.ctx.fillStyle = @color
        bmd.ctx.beginPath()
        bmd.ctx.arc(@radius, @radius, @radius, 0, Math.PI * 2, true)
        bmd.ctx.closePath()
        bmd.ctx.fill()

        @sprite = game.add.sprite(@center.x, @center.y, bmd)
        @sprite.anchor.set .5, .5

        @sprite.inputEnabled = true

    addEmitter: (game, maxParticles) ->
        emitter = new ProjectileEmitter(this, game, maxParticles)
        emitter.particleClass = @particleClass
        game.particles.add(emitter)
        emitter.gravity = 0
        emitter.makeParticles("projectile#{@id}")
        @emitter = emitter

    # Point the launcher at a world coordinate
    setDirection: (x, y) ->
        @launcherAngle = Phaser.Math.angleBetween(@center.x, @center.y, x, y)

    startEmitting: ->
        if @emitting or not @canLaunch()
            return
        @emitter.start(false, 20000, @launchPeriod, 0)
        @emitting = true

    stopEmitting: ->
        if not @emitting
            return
        @emitter.on = false
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

    update: (gameState) ->
        if @emitter
            if @emitting and not @canLaunch()
                @stopEmitting()
            angle = @launcherAngle
            sin = Math.sin(angle)
            cos = Math.cos(angle)
            xspeed = cos * @launchSpeed + @velocity.x
            yspeed = sin * @launchSpeed + @velocity.y
            @emitter.setXSpeed(xspeed - @launchJitter, xspeed + @launchJitter)
            @emitter.setYSpeed(yspeed - @launchJitter, yspeed + @launchJitter)
            @emitter.emitX = @center.x + @radiusE * cos
            @emitter.emitY = @center.y + @radiusE * sin
            @emitter.forEachExists(gameState.updateGravity, gameState)

    # for overriding
    receiveProjectile: (particle) ->

class Venus extends Planet
    particleClass: Baby
    constructor: (args...) ->
        super(args...)
        @rnd = new Phaser.RandomDataGenerator
        @females = new Population([
            0,
            1000,
            950,
            900,
            850,
            800,
            750,
            700,
            650,
            600,
        ])
        @males = new Population([0, 0, 0])
    receiveProjectile: (particle) ->
        particle.receiveByVenus(this)
    advanceYear: ->
        @females.increaseAges()
        @males.increaseAges()

    canLaunch: ->
        return @males.getTotal() >= tweaks.babiesInProjectile
    onLaunch: ->
        pyramid = @males.agePyramid
        @males.remove(tweaks.babiesInProjectile)

class Mars extends Planet
    particleClass: Sperm

    constructor: (args...) ->
        super(args...)
        @spermAmount = 0
        @males = new Population([
            0,
            1000,
            950,
            900,
            850,
            800,
            750,
            700,
            650,
            600,
        ])

    receiveProjectile: (particle) ->
        particle.receiveByMars(this)

    produceSperm: ->
        spermProduction = Math.ceil(@males.getFertilePopulation() * tweaks.maleFertility)
        @spermAmount += spermProduction
        if @spermAmount > tweaks.maxSpermBank
            @spermAmount = tweaks.maxSpermBank

    advanceYear: ->
        @males.increaseAges()

    canLaunch: ->
        return @spermAmount > 0

    onLaunch: ->
        @spermAmount -= 1

planetData = [
    # 0 venus
    {
        class: Venus
        color: '#b77424'
        diameter: 30
        orbitalPeriod: Math.round(.6 * tweaks.yearLength)
        orbitalDistance: 107
        orbitPhase: .3
        gravity: 1e5
        launchPeriod: 1000
        launchSpeed: 250
    }
    # 1 mars
    {
        class: Mars
        color: '#d84e1e'
        diameter: 15
        orbitalPeriod: Math.round(1.88 * tweaks.yearLength)
        orbitalDistance: 220
        orbitPhase: 0
        gravity: 1e5
        launchPeriod: 20
        launchSpeed: 200
        launchJitter: 2
    }
    # mercury
    {
        color: '#556677'
        diameter: 12
        orbitPhase: Math.PI * 2 * .6
        orbitalPeriod: Math.round(.24 * tweaks.yearLength)
        orbitalDistance: 40
        gravity: .3e5
    }
    # earth
    {
        color: '#252983'
        diameter: 32
        orbitPhase: Math.PI / 2
        orbitalPeriod: tweaks.yearLength
        orbitalDistance: 150
        gravity: 1e5
    }
    # sun
    {
        color: '#ffebd8'
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

        @planets = (new (data.class or Planet)(i, data) for data, i in planetData)
        @planets[0].addEmitter(@game, 1000)
        @planets[1].addEmitter(@game, 1000)

        @game.input.onDown.add(
            (pointer, event) ->
                for planet in @planets
                    if planet.emitter and not planet.emitting and planet.sprite.input.pointerOver(pointer.id)
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

        @populationView0 = new PopulationView(@game, @planets[0].females, 'Females on Venus (age groups)', 5)
        @populationView0b = new PopulationView(@game, @planets[0].males, 'Males on Venus (age groups)', 100)
        @populationView1 = new PopulationView(@game, @planets[1].males, 'Males on Mars (age groups)', @game.width - 220)

        @startTime = @game.time.now  # ms
        @year = 0
        @tickTimer = @game.time.create()
        @tickTimer.loop(
            tweaks.tickLength,
            ->
                @planets[1].produceSperm()
            this
        )
        @tickTimer.start()
        @game.time.add(@tickTimer)

        return

    update: ->
        gameTime = @game.time.elapsedSecondsSince(@startTime)
        for planet in @planets
            planet.setTime(gameTime)
        newYear = Math.floor(gameTime / tweaks.yearLength)
        if newYear != @year
            @planets[0].advanceYear()
            @planets[1].advanceYear()
            @year = newYear

        for planet in @planets
            planet.setDirection(@game.input.worldX, @game.input.worldY)
            planet.update(this)

        @populationView0.update()
        @populationView0b.update()
        @populationView1.update()
        return

    updateGravity: (particle) ->
        g = particle.body.gravity
        g.x = g.y = 0
        for planet in @planets
            dx = particle.x - planet.center.x
            dy = particle.y - planet.center.y
            distanceSquared = dx * dx + dy * dy
            if distanceSquared < planet.radiusSquared
                planet.receiveProjectile(particle)
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
    game = new Phaser.Game(800, 600, Phaser.CANVAS, 'LD30')
    game.state.add('menu', MenuState)
    game.state.add('game', GameState)
    game.state.start('game')

start()
