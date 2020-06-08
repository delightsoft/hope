{checkTagName, err: {tooManyArgs, invalidArg, isResult}} = require '../utils'

Result = require '../result'

BitArray = require '../bitArray'

compile = (result, collection) ->

  invalidArg 'result', result unless isResult result
  invalidArg 'collection', collection unless typeof collection == 'object' && collection != null && collection.hasOwnProperty('$$list')
  tooManyArgs() unless arguments.length <= 2

  tags =

    all: (new BitArray collection).invert()

  _addTag = (result, dupCheck, tag, item) ->

    if (tag = tag.trim()).length > 0

      if dupCheck.hasOwnProperty tag

        result.warn 'dsc.duplicatedTag', value: tag

      else

        dupCheck[tag] = true

        unless checkTagName tag

          result.error 'dsc.invalidName', value: tag

        else if tag == 'all'

          result.error 'dsc.reservedName', value: 'all'

        else

          (if tags.hasOwnProperty(tag) then tags[tag]

          else tags[tag] = new BitArray collection)

          .set item.$$index

    return

  list = if (isFlat = collection.hasOwnProperty('$$flat')) then collection.$$flat.$$list else collection.$$list

  item = undefined

  result.context ((path) -> (Result.prop 'tags', Result.item item.name) path), ->

    for item in list when item.hasOwnProperty('$$src') && item.$$src.hasOwnProperty('tags')

      dupCheck = {}

      srcTags = item.$$src.tags

      if typeof srcTags == 'string'

        for tag in srcTags.split ','

          _addTag result, dupCheck, tag, item

      else if Array.isArray srcTags

        for tag, i in srcTags

          if typeof tag == 'string'

            _addTag result, dupCheck, tag, item

          else

            result.error 'dsc.invalidTagValue', value: tag, index: i

      else

        result.error 'dsc.invalidValue', value: srcTags

  if isFlat

    v.fixVertical() for k, v of tags

  collection.$$tags = tags

  collection # compiler =

# ----------------------------

module.exports = compile
