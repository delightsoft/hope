{invalidArg, invalidOption, unknownOption} = require '../../utils/_err'

$$wasTouchedBuilder = (fieldsDesc) ->

  checks = for fieldName, fieldDesc of fieldsDesc when ~['structure', 'subtable'].indexOf(fieldDesc.type)

    do (name = fieldDesc.name, $$wasTouched = fieldDesc.fields.$$wasTouched) ->

      if fieldDesc.type == 'structure'

        (fieldsLevel) -> $$wasTouched fieldsLevel[name]

      else

        (fieldsLevel) ->

          if Array.isArray fieldsLevel[name] # TODO: Убрать после того как сделаем $$fix для всех входящих данных

            for row in fieldsLevel[name]

              return true if $$wasTouched row

          return false # (fieldsLevel) ->

  (fieldsLevel) -> # (fieldsDesc) ->

    unless fieldsLevel.hasOwnProperty('$$touched')

      return true

    else

      for key of fieldsLevel.$$touched

        return true

      for check in checks

        return true if check fieldsLevel

    return false # (fieldsLevel) ->

# ----------------------------

module.exports = $$wasTouchedBuilder
