moveAway = (reg)-> ->
    if reg.test @path
        @dest = null

module.exports = (kit) ->
    ###*
     * compile coffee and lint
     * @param  {Object}         opts        options
     * @option {array | string} disable     coffeelint rule to be disabled
     * @option {boolean}        useCache    use nokit cache
    ###
    coffee: (opts = {}) ->
        cfg = require './coffeelint-strict.json'
        if disable = opts.disable
            disable = [disable] if not Array.isArray disable
            disable.forEach (rule) -> cfg[rule].level = 'ignore' if cfg[rule]
        drives = kit.require 'drives'

        kit.warp ['src', 'lib', 'libs', 'test', 'benchmark'].map (n) -> "#{n}/**/*.coffee"
        .load drives.reader isCache: !! opts.useCache
        .load drives.coffeelint config: cfg
        .load drives.coffee()
        .load moveAway /(test|benchmark)\//
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
