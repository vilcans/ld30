tweaks = {
    tickLength: 100  # ms
    yearLength: 20
    babiesInProjectile: 5000
    babiesPerSperm: 100
    babyProbability: 1
    # Number of sperms produced per man per tick
    maleFertility: .0001
    maxSpermBank: 1000

    femaleMortality: {
        percentage: .003
        absolute: 10
    }
    maleMortality: {
        percentage: .003
        absolute: 10
    }
    fertilityAge: 2

    timeBetweenSpermSounds: 100
}

monthNames = [
    'Janary', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'
]

class PodView
    constructor: (@game) ->
        @maxPods = 10

        distance = 20

        @group = @game.add.group(null, 'pods')
        @sprites = []
        for i in [0...@maxPods]
            sprite = @game.add.sprite(5 + distance * i, @game.height - 5, 'pod', null) #@group)
            sprite.anchor.set(0, 1)
            sprite.fixedToCamera = true
            sprite.visible = false
            @sprites.push(sprite)
        @group.fixedToCamera = true

    update: (numberOfPods) ->
        for i in [0...@sprites.length]
            @sprites[i].visible = i < numberOfPods

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
        mothers = venus.females.getFertilePopulation()
        if mothers <= 0
            return

        girls = Math.round((venus.rnd.frac() + venus.rnd.frac() + venus.rnd.frac()) / 3 * tweaks.babiesPerSperm)
        venus.females.addBabies(girls)
        venus.males.addBabies(tweaks.babiesPerSperm - girls)
        if venus.gameState.game.time.now - venus.gameState.lastSpermPlay > tweaks.timeBetweenSpermSounds
            venus.gameState.sounds.receiveSperm.play()
            venus.gameState.lastSpermPlay = venus.gameState.game.time.now

    receiveByMars: (mars) ->
        # wasted

class Baby extends Phaser.Particle
    quantity: 100
    receiveByVenus: (venus) ->
        # returned to Venus; wasted
    receiveByMars: (mars) ->
        mars.males.addBabies(tweaks.babiesInProjectile)
        mars.gameState.sounds.receiveBaby.play()

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

    prepare: (gameState) ->
        @gameState = gameState

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
        @emitter.start(false, 20000, @launchPeriod, 0)
        @emitting = true

    stopEmitting: ->
        if not @emitting
            return
        @emitter.on = false
        @emitting = false

    select: (pointer) ->
        @selectedWithPointer = pointer
        if not @emitting and @canLaunch()
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
        @podCount = 0
        @females = new Population([
            0,
            0,
            95000 / 2,
            90000 / 2,
            85000 / 2,
            80000 / 2,
            75000 / 2,
            70000 / 2,
            65000 / 2,
            60000 / 2,
        ], tweaks.fertilityAge, tweaks.femaleMortality)
        @males = new Population([0, 0], tweaks.fertilityAge, tweaks.maleMortality)
    receiveProjectile: (particle) ->
        particle.receiveByVenus(this)
    advanceYear: ->
        @females.increaseAges()
        @males.increaseAges()

    canLaunch: ->
        return @podCount > 0 and @males.getTotal() >= tweaks.babiesInProjectile and @females.getFertilePopulation() > 0

    updatePodCount: ->
        t = Math.floor(@males.getTotal() / tweaks.babiesInProjectile)
        if t == @podCount
            return
        #if t > @podCount
        #    play new pod sound
        @podCount = t

    onLaunch: ->
        pyramid = @males.agePyramid
        @males.remove(tweaks.babiesInProjectile)

        @gameState.sounds.baby.play()

class Mars extends Planet
    particleClass: Sperm

    constructor: (args...) ->
        super(args...)
        @spermAmount = 0
        @males = new Population([
            0,
            0,
            95000 / 2,
            90000 / 2,
            85000 / 2,
            80000 / 2,
            75000 / 2,
            70000 / 2,
            65000 / 2,
            60000 / 2,
        ], tweaks.fertilityAge, tweaks.maleMortality)

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
        return @spermAmount > 0 and @males.getFertilePopulation() > 0

    onLaunch: ->
        @spermAmount -= 1

    startEmitting: (args...) ->
        super(args...)
        @gameState.sounds.sperm.play('', undefined, undefined, true)

    stopEmitting: (args...) ->
        super(args...)
        @gameState.sounds.sperm.stop()

planetData = [
    # 0 venus
    {
        class: Venus
        color: '#b77424'
        diameter: 30 * 2
        orbitalPeriod: Math.round(.6 * tweaks.yearLength)
        orbitalDistance: 107 * 2
        orbitPhase: Math.PI
        gravity: 2e5
        launchPeriod: 500
        launchSpeed: 250 * 2
    }
    # 1 mars
    {
        class: Mars
        color: '#d84e1e'
        diameter: 15 * 2
        orbitalPeriod: Math.round(1.88 * tweaks.yearLength)
        orbitalDistance: 330 #220 * 2
        orbitPhase: 0
        gravity: 2e5
        launchPeriod: 10
        launchSpeed: 200 * 2
        launchJitter: 10
    }
    # mercury
    {
        color: '#556677'
        diameter: 12 * 2
        orbitPhase: Math.PI * 2 * .6
        orbitalPeriod: Math.round(.24 * tweaks.yearLength)
        orbitalDistance: 40 * 2
        gravity: .6e5
    }
    # earth
    {
        color: '#252983'
        diameter: 32 * 2
        orbitPhase: Math.PI / 2
        orbitalPeriod: tweaks.yearLength
        orbitalDistance: 280
        gravity: 2e5
    }
    # sun
    {
        color: '#ffebd8'
        diameter: 60
        orbitalPeriod: 1
        orbitalDistance: 0
        gravity: 2e6
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
        @game.load.image('pod', 'assets/baby.png')

        @game.load.audio('sperm', ['assets/sperm.ogg'])
        @game.load.audio('baby', ['assets/baby.ogg'])
        @game.load.audio('receive-sperm', ['assets/receive-sperm.ogg'])
        @game.load.audio('receive-baby', ['assets/receive-baby.ogg'])
        @game.load.audio('music', ['assets/LD30.ogg'])

    create: ->
        @gameOn = true
        @lastSpermPlay = 0

        @sounds = {
            sperm: @game.add.audio('sperm', .3, true)
            baby: @game.add.audio('baby', .5, false)
            receiveSperm: @game.add.audio('receive-sperm', .3, false)
            receiveBaby: @game.add.audio('receive-baby', .7, false)
            music: @game.add.audio('music', .5, true)
        }
        @sounds.music.play()

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

        for planet in @planets
            planet.prepare(this)

        @populationView0 = new PopulationView(
            @game,
            @planets[0].females, @planets[0].males,
            'Females on Venus (age groups)',
            5, {
                bar: 0xff8800
                barUnderage: 0xffcc88
                secondaryBar: 0x88ccff
            },
            false
        )
        @populationView1 = new PopulationView(
            @game,
            @planets[1].males, null,
            'Males on Mars (age groups)',
            @game.width - 220, {
                bar: 0x0088ff
                barUnderage: 0x88ccff
            }, true
        )

        @spermView = @game.add.text(@game.width - 220, @game.height - 16, '----', { font: "16px Arial", fill: '#ffffff' })
        @spermView.fixedToCamera = true

        @podView = new PodView(@game)

        @startTime = @game.time.now  # ms
        @year = 0
        @gameTime = 0
        @tickTimer = @game.time.create()
        @tickTimer.loop(
            tweaks.tickLength,
            ->
                @planets[1].produceSperm()
                @spermView.text = "Sperm Bank: #{@planets[1].spermAmount}"
                @planets[0].updatePodCount()
                @planets[0].females.randomKills()
                @planets[1].males.randomKills()
                @podView.update(@planets[0].podCount)
                if @planets[0].females.getFertilePopulation() == 0 or @planets[1].males.getFertilePopulation() == 0
                    @setGameOver()
            this
        )
        @tickTimer.start()
        @game.time.add(@tickTimer)

        @dateView = @game.add.text(5, 0, @getDateText(), { font: "16px Arial", fill: '#ffffff' })
        @dateView.fixedToCamera = true

        return

    setGameOver: ->
        @populationView0.update()
        @populationView1.update()

        @gameOn = false
        @sounds.music.stop()
        @tickTimer.stop()
        t = @game.add.text(
            @game.width / 2, @game.height / 2,
            'GAME\n\nOVER',
            style = { font: '80px Arial', fill: '#ffffff', align: 'center' }
        )
        t.anchor.set(.5, .5)
        t.fixedToCamera = true

        t = @game.add.text(
            @game.width / 2, @game.height - 140,
            'Humankind is doomed',
            style = { font: '32px Arial', fill: '#888888', align: 'center' }
        )
        t.anchor.set(.5, .5)
        t.fixedToCamera = true

        t = @game.add.text(
            @game.width / 2, @game.height - 140,
            'Humankind is doomed',
            style = { font: '32px Arial', fill: '#888888', align: 'center' }
        )
        t.anchor.set(.5, .5)
        t.fixedToCamera = true

        @restartButton = @game.add.text(
            @game.width / 2, @game.height - 64,
            'Restart',
            style = { font: 'bold 32px Arial', fill: '#888888', align: 'center' }
        )
        @restartButton.fixedToCamera = true
        @restartButton.anchor.set(.5, 1)
        @restartButton.inputEnabled = true
        @restartButton.events.onInputDown.add(
            (object, pointer) ->
                @game.state.start('menu')
            this
        )

    getDateText: ->
        month = Math.floor(@gameTime % (tweaks.yearLength * 12)) % 12
        return "#{monthNames[@month]} #{@year + 2100}"

    update: ->
        if not @gameOn
            return

        @gameTime = @game.time.elapsedSecondsSince(@startTime)
        for planet in @planets
            planet.setTime(@gameTime)
        newYear = Math.floor(@gameTime / tweaks.yearLength)
        newMonth = Math.floor(@gameTime / tweaks.yearLength * 12) % 12
        if newYear != @year
            @planets[0].advanceYear()
            @planets[1].advanceYear()
            @year = newYear
        if newMonth != @month
            @month = newMonth
            @dateView.text = @getDateText()

        for planet in @planets
            planet.setDirection(@game.input.worldX, @game.input.worldY)
            planet.update(this)

        @populationView0.update()
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
            @game.width / 2, 60,
            'PANSPERMIA',
            style = { font: '64px Arial', fill: '#ffffff', align: 'center' }
        )
        t.anchor.set(.5, 0)

        @startButton = @game.add.text(
            @game.width / 2, @game.height - 64,
            'Start',
            style = { font: 'bold 32px Arial', fill: '#888888', align: 'center' }
        )
        @startButton.anchor.set(.5, 1)
        @startButton.inputEnabled = true
        @startButton.events.onInputDown.add(
            (object, pointer) ->
                @game.state.start('game')
            this
        )

    update: ->

    render: ->

start = ->
    game = new Phaser.Game(700, 700, Phaser.CANVAS, 'LD30')
    game.state.add('menu', MenuState)
    game.state.add('game', GameState)
    game.state.start('game')

start()
