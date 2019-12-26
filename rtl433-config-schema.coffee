module.exports = {
  title: "rtl433 config options"
  type: "object"
  properties:
    debug:
      description: "Log information for debugging, including received messages"
      type: "boolean"
      default: false
    freq:
      description: "Carrier frequency (in Hz)"
      type: "number"
      default: 433920000
    ###parameter:
      description: "parameter for rtl_433, see commandline rtl_433 -h"
      type: "string"
      default: "-R 03 -R 19 -R 52"###
    detectionLevel:
      description: "Detection level used to determine pulses [0-16384]"
      type: "number"
      default: 0
}