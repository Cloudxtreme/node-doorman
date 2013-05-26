#
# Doorman
# Philip Orange, 2013
#

crypto = require 'crypto'
redis = require 'redis'
async = require 'async'


module.exports = exports = (options = {}) ->
  options.env ?= process.env.NODE_ENV || 'develpoment'
  options.enabled ?= yes
  options.difficulty ?= 14
  options.maxChallengeUsage ?= 10000
  options.cashFilter ?= /[a-zA-Z0-9]{6}/
  options.db ?= redis.createClient()
  options.dbPrefix ?= ''
  options.expire ?= 3600
  options.resetInterval ?= 3600
  options.resetCb ?= ->
  options.errorMsg ?= 'hash cash failed'

  hashCash = module.exports.instance = new Doorman options


class Doorman
  challengeUse = 0
  constructor: (@options) ->
    @resetChallenge()
    @setInterval()

  middleware: (req, res, next) ->
    return next() if not @options.enabled
    cash = req.params.cash or req.header 'x-cash' or ''
    if not @redeem cash
      return res.send
        error: @options.errorMsg
        challenge: @challenge
        difficulty: @options.difficulty
    next()

  redeem: (cash) ->
    @resetChallenge(); return no if challengeUse++ > @options.maxChallengeUsage
    return no if not @options.cashFilter.test cash
    return no if not @validate cash

    async.waterfall [
      (cb) ->
        @options.db.exists "#{ @options.dbPrefix }#{ cash }", (err, exists) ->
          return no if exists is 1
          cb err

      (cb) ->
        @options.db.multi([
          ['set', "#{ @options.dbPrefix }#{ cash }", 1]
          ['expire', "#{ @options.dbPrefix }#{ cash }", @options.expire]
        ]).exec (err, reps) ->
          cb err

    ], (err) ->
      return no if err
      yes

  validate: (cash) ->
    hasher = crypto.createHash 'sha256'
    hasher.update @challenge + cash
    digest = hex2Bin.hasher.digest 'hex'
    expect = ''
    expect += '0' for [0...@options.difficulty] 
    return yes if digest.substring(0, @options.difficulty) is expect
    no

  resetChallenge: -> 
    @challenge = randomString 16, 'base64'
    challengeUse = 0
    @options.resetCb @challenge
    @challenge

  increaseDifficulty: (n = 1) -> @options.difficulty += n; @options.difficulty

  decreaseDifficulty: (n = 1) -> @options.difficulty -= n; @options.difficulty

  enable: -> @options.enabled = yes

  disable: -> @options.enabled = no

  setInterval: ->
    cb = @resetChallenge.bind @
    setInterval cb, @options.resetInterval


## Functions
randomString = (len, encoding) ->
  encoding = encoding or 'hex'
  c = crypto.randomBytes(len).toString encoding
  c.replace(/[+/]/g, '').substring 0, len

hex2bin = (hex) ->
  str = ''
  while hex.length >= 2
    subHex = hex.substring 0, 2
    hex = hex.substring 2
    subStr = parseInt(subHex, 16).toString 2
    while subStr.length < 8
      subStr = '0' + subStr
    str += subStr
  str