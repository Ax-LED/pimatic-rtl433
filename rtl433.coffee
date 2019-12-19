module.exports = (env) ->
  Promise = env.require 'bluebird'
  M = env.matcher
  events = env.require 'events'
  exec = Promise.promisify(require("child_process").exec)
  spawn = require('child_process').spawn
  settled = (promise) -> Promise.settle([promise])
  readline = require('readline');

  class rtl433 extends events.EventEmitter
    constructor: (framework,config) ->
      @config = config
      @framework = framework
      env.logger.debug("Launching rtl_433")
      #env.logger.debug "#{__dirname}/bin/rtl_433", "-f #{@config.freq} -R 36 -F csv -q -l #{@config.detectionLevel}"
      env.logger.debug "#{__dirname}/bin/rtl_433", "-f #{@config.freq} -R 03 -R 19 -R 52 -F csv -l #{@config.detectionLevel}"
      #proc = spawn("#{__dirname}/bin/rtl_433",['-f', @config.freq, '-R', '36', '-F', 'csv', '-q', '-l', @config.detectionLevel])
      proc = spawn("#{__dirname}/bin/rtl_433",['-f', @config.freq, '-R', '03', '-R', '19', '-R', '52', '-F', 'csv', '-l', @config.detectionLevel])
      proc.stdout.setEncoding('utf8')
      proc.stderr.setEncoding('utf8')
      rl = readline.createInterface({ input: proc.stdout })

      rl.on('line', (line) => 
        @_dataReceived(line)
      )

      proc.stderr.on('data',(data) =>
        lines = data.split(/(\r?\n)/g)
        env.logger.warn line for line in lines when line.trim() isnt ''
      )

      proc.on('close',(code) =>
        if code!=0
          env.logger.error "rtl_433 returned", code
        rl.close()
      )

    _dataReceived: (data) ->
      env.logger.debug data
      datas = {};
      datas = data.split(",")
      if datas.length == 7
        result = {}
        result = {
            "sensorId": datas[2],
            "ampere": parseFloat datas[3],
            "battery": datas[5]=="LOW"
        }
        env.logger.debug "Got measure (id:" + result.sensorId + ", amps: " + result.ampere + ", battery:" + result.battery + ")"
        @emit('power', result)

  Promise.promisifyAll(rtl433.prototype)

  class EfergyE2 extends env.plugins.Plugin

    init: (app, @framework, @config) =>

      @rtl433 = new rtl433(@framework, @config)

      deviceConfigDef = require("./device-config-schema")

      @framework.deviceManager.registerDeviceClass("EfergyE2Sensor", {
        configDef: deviceConfigDef.EfergyE2Sensor, 
        createCallback: (config, lastState) => return new EfergyE2Sensor(config, lastState, @rtl433)
      })

  plugin = new EfergyE2()
  
  class EfergyE2Sensor extends env.devices.Sensor

    constructor: (@config, lastState, @rtl433) ->
      @name = @config.name
      @id = @config.id
      @sensorId = @config.sensorId
      @_voltage = parseFloat(@config.volt)

      @_ampere = lastState?.ampere?.value
      @_watt = lastState?.watt?.value
      @_lowBattery = lastState?.lowBattery?.value

      @attributes = {}

      @attributes.watt = {
        description: "the messured Wattage"
        type: "number"
        unit: 'W'
        acronym: 'Power'
      }
      
      @attributes.lowBattery = {
        description: "Battery status"
        type: "boolean"
        labels: ["low", 'ok']
        icon:
          noText: true
          mapping: {
            'icon-battery-filled': false
            'icon-battery-empty': true
          }
      }


      @rtl433.on("power", (result) =>
        if result.sensorId is @config.sensorId
          env.logger.debug "power <- " , result
          @_ampere = result.ampere
          @emit "ampere", @_ampere
          @_watt = @_voltage*@_ampere
          @emit "watt", @_watt
          @_lowBattery = result.battery
          @emit "lowBattery", @_lowBattery
      )
      super()
      
    getWatt: -> Promise.resolve @_watt
    getBattery: -> Promise.resolve @_batterystat
    getAmpere: -> Promise.resolve @_ampere
    getLowBattery: -> Promise.resolve @_lowBattery

  return plugin