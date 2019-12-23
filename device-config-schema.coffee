# #Shell device configuration options
module.exports = {
  title: "pimatic-efergye2 device config schemas"
  EfergyE2Sensor: {
    title: "Efergy E2 config options"
    type: "object"
#    extensions: ["xLink", "xAttributeOptions"]
    properties:
      sensorId:
        description: "Efergy E2 sensor id"
        type: "string"
        default: ""
      volt:
        description: "Line voltage"
        type: "number"
        default: 230
  },
  RTL433Temperature2: {
    title: "RTL433Temperature config options"
    type: "object"
    #extensions: ["xLink", "xAttributeOptions"]
    properties:
      #AxLED
      sensorId:
        description: "sensor id of 433Mhz device (f.e. Temp Sensor)"
        type: "string"
        default: ""
      #AxLED
      ###
      protocols:
        description: "The protocols to use."
        type: "array"
        default: []
        format: "table"
        items:
          type: "object"
          properties:
            name:
              type: "string"
            options:
              description: "The protocol options"
              type: "object"
      processingTemp:
        description: "
          expression that can preprocess the value, $value is a placeholder for the temperature
          value itself."
        type: "string"
        default: "$value"
      processingHum:
        description: "
          expression that can preprocess the value, $value is a placeholder for the humidity
          value itself."
        type: "string"
        default: "$value"
      isFahrenheit:
        description: "
          boolean that sets the right units if the temperature is to be reported in
           Fahrenheit"
        type: "boolean"
        default: false
        ###
  },
  RTL433Temperature: {
    title: "HomeduinoRFTemperature config options"
    type: "object"
    extensions: ["xLink", "xAttributeOptions"]
    properties:
      #AxLED
      sensorId:
        description: "sensor id of 433Mhz device (f.e. Temp Sensor)"
        type: "string"
        default: ""
      #AxLED
      protocols:
        description: "The protocols to use."
        type: "array"
        default: []
        format: "table"
        items:
          type: "object"
          properties:
            name:
              type: "string"
            options:
              description: "The protocol options"
              type: "object"
      processingTemp:
        description: "
          expression that can preprocess the value, $value is a placeholder for the temperature
          value itself."
        type: "string"
        default: "$value"
      processingHum:
        description: "
          expression that can preprocess the value, $value is a placeholder for the humidity
          value itself."
        type: "string"
        default: "$value"
      isFahrenheit:
        description: "
          boolean that sets the right units if the temperature is to be reported in
           Fahrenheit"
        type: "boolean"
        default: false
  }
}
