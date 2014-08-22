# LD29

My entry for [Ludum Dare](http://www.ludumdare.com/compo/) 29.

## Install and run

    bower install
    npm install
    (cd test && bower install)
    grunt serve

## Audio

    sudo apt-get install vorbis-tools
    oggenc --downmix --resample=22050 -q 3 -o app/assets/foo.ogg asset-sources/foo.wav
