# While working with the specs we discovered a problem: the loaded files get out of sync, because
# jasmine resets require.cache on a regular basis.  For example: a problem arose with the check
# `result instanceof Result` in loader when a Result object is created in the specs code.  Merging the loaded
# parts into a single loading file resolved the problem.
#
# UPD: Nevertheless, even this approach did not solve the problem - so instead of instanceof, we use methods like err.isResult

require './polyfills'


module.exports =

  Result: require './result'

  BitArray: require './bitArray'

  Reporter: require './reporter'

  loader: require './loader'

  i18n: require './i18n'

  utils: require './utils'

  types: require './types'

  tags: require './tags'

  config: require './config'

  sortedMap: require './sortedMap'

  flatMap: require './flatMap'

  compareStructures: require './compareStructures'

  # docs: require './docs'

module.exports.default = module.exports
