#!/usr/bin/env coffee

#
# Doorman Cli
# Philip Orange, 2013
#

crypto = require 'crypto'
optimist = require 'optimist'


## Stdin
argv = optimist
  .usage('Generate hashcash')
  .default('d', 18)
  .alias('d', 'difficulty')
  .describe('d', 'Hashcash difficulty')
  .default('l', 10)
  .alias('l', 'length')
  .describe('l', 'Hashcash string length')
  .default('c', 'base64')
  .alias('c', 'charset')
  .describe('c', 'Hashcash string charset')
  .boolean('v')
  .alias('v', 'verbose')
  .describe('v', 'Also print time taken and binary_digest(challenge + hashcash)')
  .boolean('h')
  .alias('h', 'help')
  .describe('h', 'Show this help message')
  .argv


## Usage
if not argv._[0]? or argv.help
  optimist.showHelp()
  process.exit()


## Functions
randomString = (len, encoding) ->
  encoding = encoding || 'hex'
  c = crypto.randomBytes(len).toString encoding
  c.replace(/[+/]/g, '').substring 0, len

hex2Bin = (hex) ->
  str = ''
  while hex.length >= 2
    subHex = hex.substring 0, 2
    hex = hex.substring 2
    subStr = parseInt(subHex, 16).toString 2
    while subStr.length < 8
      subStr = '0' + subStr
    str += subStr
  str
  
validate = (cash, difficulty) ->
  hasher = crypto.createHash 'sha256'
  hasher.update cash
  hexDigest = hasher.digest 'hex'
  digest = hex2Bin hexDigest
  expect = ''
  expect += '0' for [0...difficulty] 
  return yes if digest.substring(0, difficulty) is expect
  no

mint = (challenge, length=10, difficulty=16, charset='base64') ->
  loop
    ore = randomString length, charset
    trial = challenge + ore
    break if validate trial, difficulty
  ore


## Main
start = (new Date()).valueOf()
cash = mint argv._[0], argv.length, argv.difficulty, argv.charset

if argv.verbose
  trial = argv._[0] + cash
  hasher = crypto.createHash 'sha256'
  hasher.update trial
  hexDigest = hasher.digest 'hex'
  digest = hex2Bin hexDigest
  t = ((new Date()).valueOf() - start) / 1000.0

  console.log {hashcash: cash, time: t, digest: digest}
else
  console.log cash