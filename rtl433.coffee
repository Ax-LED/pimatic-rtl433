module.exports = (env) ->
  Promise = env.require 'bluebird'
  #AxLED
  assert = env.require 'cassert'
  _ = env.require('lodash')
  #AxLED
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
      env.logger.debug "#{__dirname}/bin/rtl_433", "-f #{@config.freq} -R 03 -R 19 -R 52 -R 141 -F csv -l #{@config.detectionLevel}"
      #proc = spawn("#{__dirname}/bin/rtl_433",['-f', @config.freq, '-R', '36', '-F', 'csv', '-q', '-l', @config.detectionLevel])
      proc = spawn("#{__dirname}/bin/rtl_433",['-f', @config.freq, '-R', '03', '-R', '19', '-R', '52', '-R', '141', '-F', 'csv', '-l', @config.detectionLevel])
      #proc = spawn("#{__dirname}/bin/rtl_433",['-f', @config.freq, '-R 03 -R 19 -R 52', '-F', 'csv', '-l', @config.detectionLevel])
      #proc = spawn("#{__dirname}/bin/rtl_433",['-f', @config.freq, ['-R 03 -R 19 -R 52'], '-F', 'csv', '-l', @config.detectionLevel])
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
      if datas.length == 15 #Data Length variiert, abhängig von den RTL_433 Parametern
        result = {}
        result = {
            "model": datas[3],
            "sensorId": datas[5],
            "channel": datas[7],
            "lowbattery": datas[8],
            "temperatureC": parseFloat(datas[9]),
            "humidity": parseInt(datas[10]),
            "temperatureF": parseFloat(datas[12])
        }
        env.logger.debug "Got measure (model:" + result.model + ", sensorId: " + result.sensorId + ", channel: " + result.channel + ", lowbattery:" + result.lowbattery + ", TempC:" + result.temperatureC + ", Humidity:" + result.humidity + ", TempF:" + result.temperatureF + ")"
        @emit('temp', result)

  Promise.promisifyAll(rtl433.prototype)

  class Rtl433 extends env.plugins.Plugin

    init: (app, @framework, @config) =>

      @rtl433 = new rtl433(@framework, @config)

      deviceConfigDef = require("./device-config-schema")

      @framework.deviceManager.registerDeviceClass("RTL433Temperature", {
        configDef: deviceConfigDef.RTL433Temperature, 
        createCallback: (config, lastState) => return new RTL433Temperature(config, lastState, @rtl433)
      })

  plugin = new Rtl433()
  
  class RTL433Temperature extends env.devices.TemperatureSensor
  
    attributes:
      temperature:
        description: "the measured temperature"
        type: "number"
        unit: '°C'
        acronym: 'T'
      humidity:
        description: "the measured humidity"
        type: "number"
        unit: '%'
        acronym: 'RH'
      lowBattery:
        description: "the battery status"
        type: "boolean"
        labels: ["low", 'ok']
        icon:
          noText: true
          mapping: {
            'icon-battery-filled': false
            'icon-battery-empty': true
          }

    constructor: (@config, lastState, @rtl433) ->
      @id = @config.id
      @name = @config.name
      @_temperature = lastState?.temperature?.value
      @_humidity = lastState?.humidity?.value
      @_lowBattery = lastState?.lowBattery?.value
      isFahrenheit = @config.isFahrenheit

      @rtl433.on("temp", (result) =>
        if result.sensorId is @config.sensorId
          env.logger.debug "Tempsensor <- " , result
          if isFahrenheit
            @_temperature = (result.temperatureF-32)*5/9 #Umrechnung in Grad
          else
            @_temperature = result.temperatureC
          @emit "temperature", @_temperature
          @_humidity = result.humidity
          @emit "humidity", @_humidity
          if result.lowbattery == 'OK' # Werte von OK in boolean true/false umwandeln
            @_lowBattery = false
          else
            @_lowBattery = true
          @emit "lowBattery", @_lowBattery
          
      )
      super()
    
    getTemperature: -> Promise.resolve @_temperature
    getHumidity: -> Promise.resolve @_humidity
    getLowBattery: -> Promise.resolve @_lowBattery

    destroy: ->
      super()

  return plugin