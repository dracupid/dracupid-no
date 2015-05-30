"use strict"

module.exports = (kit) ->
    nil = -> ->
    moveAway = (reg) -> ->
        @dest = null if reg.test @path

    compress = -> ->
        return if @dest.ext isnt '.js'
        @contents = @contents.split('\n').filter (line) ->
            line = line.trim()
            line and not (line[0] in ['/', '*'])
        .join '\n'
        @contents += '\n'

    ###*
     * compile coffee and lint
     * @param  {Object}         opts        options
     * @option {array | string} disable     coffeelint rule to be disabled
     * @option {boolean}        useCache    use nokit cache
    ###
    coffee: (opts = {}) ->
        kit._.defaults opts,
            compress: true
            useCache: false
            disable: null
        cfg = require './coffeelint-strict.json'
        if disable = opts.disable
            disable = [disable] unless Array.isArray disable
            disable.forEach (rule) -> cfg[rule].level = 'ignore' if cfg[rule]
        drives = kit.require 'drives'

        kit.warp ['src', 'lib', 'libs', 'test', 'benchmark'].map (n) -> "#{n}/**/*.*"
        .load drives.reader isCache: opts.useCache
        .load drives.auto 'lint', '.coffee': config: cfg
        .load drives.auto 'compile'
        .load moveAway /(test|benchmark)\//
        .load if opts.compress then compress() else nil()
        .run 'dist'
        .catch (e)->
            if e.line? and e.rule
                kit.Promise.resolve()
            else
                kit.Promise.reject e

    ###*
     * test using mocha
     * @param  {string="test/index.coffee"} filename    test files' name
     * @param  {Array=[]}                  mochaOpts   mocha options
    ###
    mocha: (filename = "test/index.coffee", mochaOpts = []) ->
        kit.spawn 'mocha', ['-r', 'coffee-script/register', filename].concat mochaOpts
        .catch ->
            process.exit 1
