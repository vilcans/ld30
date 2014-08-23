class Planet
    constructor: ({@diameter, @orbitalPeriod, @orbitalDistance}) ->
        @radius = @diameter / 2
        @center = new Phaser.Point
        @angularVelocity = Math.PI * 2 / @orbitalPeriod

    setTime: (t) ->
        angle = @angularVelocity * t
        @sprite.x = @center.x = Math.sin(angle) * @orbitalDistance
        @sprite.y = @center.y = Math.cos(angle) * @orbitalDistance

    createSprite: (game) ->
        bmd = game.add.bitmapData(@diameter, @diameter)

        bmd.ctx.fillStyle = '#999999'
        bmd.ctx.beginPath()
        bmd.ctx.arc(@radius, @radius, @radius, 0, Math.PI * 2, true)
        bmd.ctx.closePath()
        bmd.ctx.fill()

        @sprite = game.add.sprite(@center.x, @center.y, bmd)
        @sprite.anchor.set .5, .5

planetData = [
    # 0 venus
    {
        diameter: 12
        orbitalPeriod: 7000
        orbitalDistance: 80
    }
    # 1 earth
    {
        diameter: 20
        orbitalPeriod: 10000
        orbitalDistance: 100
    }
    # 2 mars
    {
        diameter: 15
        orbitalPeriod: 12000
        orbitalDistance: 150
    }
    # 3 sun
    {
        diameter: 60
        orbitalPeriod: 1
        orbitalDistance: 0
    }
]
if false
    for i in [1..10]
        planetData.push
            diameter: Math.random() * 25 + 5
            orbitalPeriod: Math.random() * 10000 + 1000
            orbitalDistance: Math.random() * 90

class GameState
    preload: ->

    create: ->
        @game.world.setBounds(-1000, -1000, 2000, 2000)
        @game.world.camera.focusOnXY(0, 0)

        @planets = for data in planetData
            planet = new Planet(data)
            planet.createSprite(@game)
            planet
        return

    update: ->
        now = @game.time.now
        for planet in @planets
            planet.setTime(now)

        return

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
