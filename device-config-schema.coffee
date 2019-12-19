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
  }
}
