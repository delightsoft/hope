{checkTagName, checkTagsNamespace, err: {tooManyArgs, invalidArg, isResult}} = require '../utils'

Result = require '../result'

BitArray = require '../bitArray'

compile = (result, collection) ->

  invalidArg 'result', result unless isResult result
  invalidArg 'collection', collection unless typeof collection == 'object' && collection != null && collection.hasOwnProperty('$$list')
  tooManyArgs() unless arguments.length <= 2

  tags =

    all: (new BitArray collection).invert()

    none: new BitArray collection

  if collection.$$flat # only 'fields' are flatMap

    requiredMask = tags.required = new BitArray collection

    requiredMask.set(fld.$$index) for fld in collection.$$flat.$$list when fld.required

  _addTag = (result, dupCheck, tag, item, namespace) ->

    if (tag = tag.trim()).length > 0

      if namespace

        unless tag.indexOf('.') == -1

          return result.error 'dsc.ambiguousNamespaces', value1: "tags.#{namespace}", value2: tag

        else

          tag = "#{namespace}.#{tag}"

      if dupCheck.hasOwnProperty tag

        result.warn 'dsc.duplicatedTag', value: tag

      else

        dupCheck[tag] = true

        unless checkTagName tag

          result.error 'dsc.invalidName', value: tag

        else if ~['all', 'none', 'required'].indexOf(tag)

          result.error 'dsc.reservedName', value: tag

        else

          (if tags.hasOwnProperty(tag) then tags[tag]

          else tags[tag] = new BitArray collection)

          .set item.$$index

    return

  list = if (isFlat = collection.hasOwnProperty('$$flat')) then collection.$$flat.$$list else collection.$$list

  item = undefined

  propName = undefined

  result.context ((path) -> (Result.prop propName, Result.prop item.name) path), ->

    for item in list when item.hasOwnProperty('$$src')

      tagsProps = if item.$$src.hasOwnProperty('tags') then ['tags'] else []

      for propName of item.$$src when propName.startsWith('tags.') or propName.startsWith('tags_')

        unless checkTagsNamespace propName

          result.error 'dsc.invalidProp', value: propName

        else

          tagsProps.push propName

      dupCheck = {}

      namespace = undefined

      for propName in tagsProps

        namespace = propName.substr dotIndex + 1 if (dotIndex = propName.indexOf('.')) != -1 or (dotIndex = propName.indexOf('_')) != -1

        srcTags = item.$$src[propName]

        delete item.$$src[propName] if namespace # так как имена свойвст содержат namespace, то проще их удалить во время обработки, чем формировать список для sortedMap.finish

        if typeof srcTags == 'string'

          for tag in srcTags.split ','

            _addTag result, dupCheck, tag, item, namespace

        else if Array.isArray srcTags

          for tag, i in srcTags

            if typeof tag == 'string'

              _addTag result, dupCheck, tag, item, namespace

            else

              result.error 'dsc.invalidTagValue', value: tag, index: i

        else

          result.error 'dsc.invalidValue', value: srcTags

  v.list for k, v of tags

  collection.$$tags = tags

  collection # compiler =

# ----------------------------

module.exports = compile
