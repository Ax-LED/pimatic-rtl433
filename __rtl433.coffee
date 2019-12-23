module.exports = (env) ->
  Promise = env.require 'bluebird'
  #AxLED
  #assert = env.require 'cassert'
  #_ = env.require('lodash')
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
      env.logger.debug "#{__dirname}/bin/rtl_433", "-f #{@config.freq} -R 03 -R 19 -R 52 -F csv -l #{@config.detectionLevel}"
      #proc = spawn("#{__dirname}/bin/rtl_433",['-f', @config.freq, '-R', '36', '-F', 'csv', '-q', '-l', @config.detectionLevel])
      proc = spawn("#{__dirname}/bin/rtl_433",['-f', @config.freq, '-R', '03', '-R', '19', '-R', '52', '-F', 'csv', '-l', @config.detectionLevel])
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
      if datas.length == 7
        result = {}
        result = {
            "sensorId": datas[2],
            "ampere": parseFloat datas[3],
            "battery": datas[5]=="LOW"
        }
        env.logger.debug "Got measure (id:" + result.sensorId + ", amps: " + result.ampere + ", battery:" + result.battery + ")"
        @emit('power', result)

      #AxLED
      if datas.length == 14
        result = {}
        result = {
            "model": datas[3],
            "sensorId": datas[5],
            "channel": datas[7],
            "battery": datas[8],
            #"humidity": parseFloat(datas[10]),
            "temperatureC": parseFloat(datas[9]),
            "humidity": parseInt(datas[10]),
            "temperatureF": parseFloat(datas[12])
        }
        env.logger.debug "Got measure (model:" + result.model + ", sensorId: " + result.sensorId + ", channel: " + result.channel + ", battery:" + result.battery + ", TempC:" + result.temperatureC + ", Humidity:" + result.humidity + ", TempF:" + result.temperatureF + ")"
        @emit('temp', result)
      #AxLED

  Promise.promisifyAll(rtl433.prototype)

  class EfergyE2 extends env.plugins.Plugin

    init: (app, @framework, @config) =>

      @rtl433 = new rtl433(@framework, @config)

      deviceConfigDef = require("./device-config-schema")

      #AxLED
      #deviceClasses = [
      #  EfergyE2Sensor
      #  RTL433Temperature
      #]
      #AxLED
      ###
      @framework.deviceManager.registerDeviceClass("EfergyE2Sensor", {
        configDef: deviceConfigDef.EfergyE2Sensor, 
        createCallback: (config, lastState) => return new EfergyE2Sensor(config, lastState, @rtl433)
      })
      ###
      #AxLED
      @framework.deviceManager.registerDeviceClass("RTL433Temperature", {
        configDef: deviceConfigDef.RTL433Temperature, 
        createCallback: (config, lastState) => return new RTL433Temperature(config, lastState, @rtl433)
      })
      #AxLED

  plugin = new EfergyE2()
  
  ###
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
    ####

  #AxLED
  class RTL433Temperature extends env.devices.TemperatureSensor
  #temperature: null #AxLED
    #constructor: (@config, lastState, @board) ->
    constructor: (@config, lastState, @rtl433) -> #AxLED
      @id = @config.id
      @name = @config.name
      @_temperature = lastState?.temperature?.value
      @_humidity = lastState?.humidity?.value
      @_lowBattery = lastState?.lowBattery?.value
      @_battery = lastState?.battery?.value

      ###hasTemperature = false
      hasHumidity = false
      hasLowBattery = false # boolean battery indicator
      hasBattery = false # numeric battery indicator
      isFahrenheit = @config.isFahrenheit
      for p in @config.protocols
        checkProtocolProperties(p, ["weather"])
        _protocol = Board.getRfProtocol(p.name)
        hasTemperature = true if _protocol.values.temperature?
        hasHumidity = true if _protocol.values.humidity?
        hasLowBattery = true if _protocol.values.lowBattery?
        hasBattery = true if  _protocol.values.battery?
      #@attributes = {}

      if hasTemperature
        if isFahrenheit then tempUnit = '°F'
        else tempUnit = '°C'
        @attributes.temperature = {
          description: "the measured temperature"
          type: "number"
          unit: tempUnit
          acronym: 'T'
        }

      if hasHumidity
        @attributes.humidity = {
          description: "the measured humidity"
          type: "number"
          unit: '%'
          acronym: 'RH'
        }

      if hasLowBattery
        @attributes.lowBattery = {
          description: "the battery status"
          type: "boolean"
          labels: ["low", 'ok']
          icon:
            noText: true
            mapping: {
              'icon-battery-filled': false
              'icon-battery-empty': true
            }
        }
      if hasBattery
        @attributes.battery = {
          description: "the battery status"
          type: "number"
          unit: '%'
          displaySparkline: false
          icon:
            noText: true
            mapping: {
              'icon-battery-empty': 0
              'icon-battery-fuel-1': [0, 20]
              'icon-battery-fuel-2': [20, 40]
              'icon-battery-fuel-3': [40, 60]
              'icon-battery-fuel-4': [60, 80]
              'icon-battery-fuel-5': [80, 100]
              'icon-battery-filled': 100
            }
        }
      ###

      ###
      @board.on('rf', rfListener = (event) =>
        for p in @config.protocols
          match = doesProtocolMatch(event, p)
          if match
            now = (new Date()).getTime()
            timeDelta = (
              if @_lastReceiveTime? then (now - @_lastReceiveTime)
              else 9999999
            )
            # discard value if it is the same and was received just under two second ago
            if timeDelta < 2000
              return

            if event.values.temperature?
              variableManager = hdPlugin.framework.variableManager
              processing = @config.processingTemp or "$value"
              info = variableManager.parseVariableExpression(
                processing.replace(/\$value\b/g, event.values.temperature)
              )
              variableManager.evaluateNumericExpression(info.tokens).then( (value) =>
                #@_temperature = value
                #@emit "temperature", #@_temperature
              )
            if event.values.humidity?
              variableManager = hdPlugin.framework.variableManager
              processing = @config.processingHum or "$value"
              info = variableManager.parseVariableExpression(
                processing.replace(/\$value\b/g, event.values.humidity)
              )
              variableManager.evaluateNumericExpression(info.tokens).then( (value) =>
                #@_humidity = value
                #@emit "humidity", #@_humidity
              )
            if event.values.lowBattery?
              #@_lowBattery = event.values.lowBattery
              #@emit "lowBattery", #@_lowBattery
            if event.values.battery?
              #@_battery = event.values.battery
              #@emit "battery", #@_battery
            #@_lastReceiveTime = now
      )
      @on('destroy', () => @board.removeListener('rf', rfListener) )
      super()
      ###

      #AxLED
      @rtl433.on("temp", (result) =>
        if result.sensorId is @config.sensorId
          env.logger.debug "Tempsensor <- " , result
          #AxLED
          @_humidity = result.humidity
          @emit "humidity", @_humidity
          @_temperature = result.temperatureC
          #@_temperature = result.humidity
          @emit "temperature", @_temperature
          @_battery = result.battery
          @emit "battery", @_battery
          #AxLEd
          @_lowBattery = result.battery
          @emit "lowBattery", @_lowBattery
      )
      super()
      #AxLED
    
    #getHumidity: -> Promise.resolve(10)
    getTemperature: -> Promise.resolve @_temperature
    #getTemperature: -> Promise.resolve(11)
    getHumidity: -> Promise.resolve @_humidity
    getLowBattery: -> Promise.resolve @_lowBattery
    getBattery: -> Promise.resolve @_battery

    destroy: ->
      super()
      
  return plugin