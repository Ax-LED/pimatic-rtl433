module.exports = {
  title: "efergy E2 config options"
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
    detectionLevel:
      description: "Detection level used to determine pulses [0-16384]"
      type: "number"
      default: 8000
}