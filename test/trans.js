
var done = false

module.exports = (hit) => {
  if (done) { return null }
  hit._id = "panda id"
  hit._type = "panda type"
  hit._index = "panda index"
  hit._source.panda = "TRUE PANDA"
  done = true
  return hit
}
