# #Shell device configuration options
module.exports = {
  RTL433Temperature: {
    title: "RTL433Temperature config options"
    type: "object"
    extensions: ["xLink", "xAttributeOptions"]
    properties:
      sensorId:
        description: "sensor id of 433Mhz device (f.e. Temp Sensor)"
        type: "string"
        default: ""
      isFahrenheit:
        description: "
          boolean that sets the right units if the temperature is to be reported in
           Fahrenheit"
        type: "boolean"
        default: false
  }
}
