class Planet
    constructor: ({@diameter, @orbitalPeriod, @orbitalDistance}) ->
        @center = new Phaser.Point
        @angularVelocity = Math.PI * 2 / @orbitalPeriod

    setTime: (t) ->
        angle = @angularVelocity * t
        @sprite.x = @center.x = Math.sin(angle) * @orbitalDistance
        @sprite.y = @center.y = Math.cos(angle) * @orbitalDistance

    createSprite: (game) ->
        radius = @diameter / 2
        bmd = game.add.bitmapData(@diameter, @diameter)

        bmd.ctx.fillStyle = '#999999'
        bmd.ctx.beginPath()
        bmd.ctx.arc(radius, radius, radius, 0, Math.PI * 2, true)
        bmd.ctx.closePath()
        bmd.ctx.fill()

        @sprite = game.add.sprite(@center.x, @center.y, bmd)
        @sprite.anchor.set .5, .5

planets = [
    new Planet(
        diameter: 30
        orbitalPeriod: 10000
        orbitalDistance: 30
    )
]
for i in [1..10]
    planets.push new Planet(
        diameter: Math.random() * 25 + 5
        orbitalPeriod: Math.random() * 10000 + 1000
        orbitalDistance: Math.random() * 90
    )

class GameState
    preload: ->

    create: ->
        @game.world.setBounds(-1000, -1000, 2000, 2000)
        for planet in planets
            planet.createSprite(@game)
        return

    update: ->
        @game.world.camera.focusOnXY(0, 0)
        for planet in planets
            planet.setTime(@game.time.now)

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
