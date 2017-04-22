DSScopeStub
==============================

    module.exports =

Интерфейс DSScope нужен для работы DSDocument.

Есть три реализации DSScope:
* DSConnector
* DSScope
* DSTransaction

      class DSScopeStub

        constructor: ->
          @_findArgs = []
          @_editableDocArgs = []
          @_wait = false

        _set: ({error, doc}) ->
          return unless @_wait
          @_wait = true
          @_cb (if error then error else null), doc
          return

Метод find, производит асинхронную загрузку документа с указанным ID.  После загрузки вызывается callback с параметрами (error, doc),
где error если не null, то объект класса Result, обязательно с isError == true.

        find: (@_owner, @_docId, @_cb) ->

          @_findArgs.push {owner: @_owner, docId: @_docId, cb: @_cb}

          throw new Error "owner: #{@_owner}" unless typeof @_owner == 'object' && @_owner != null && @_owner.hasOwnProperty('$ds_ref')
          throw new Error "docId: #{@_docId}" unless typeof @_docId == 'string' && @_docId.indexOf('@') >= 0
          throw new Error "cb: #{@_cb}" unless typeof @_cb == 'function'
          throw new Error "Too many args" unless arguments.length <= 3
          @_wait = true

Метод find возвращает функцию unwait, которая позволяет отказаться от получения результата

          => @_wait = false; return

При присвоении документ в propDoc в редактируемой версии документа - документ
- проверяется, что он принадлежит к правильному dsscope
- возможно, подменяется на правильную версию (оригинальную или редактируемую) документа

        editableDoc: (_owner, _value, _propName) ->

          @_editableDocArgs.push {owner: _owner, value: _value, propName: _propName}

          throw new Error "owner: #{_owner}" unless typeof _owner == 'object' && _owner != null && _owner.hasOwnProperty('$ds_ref')
          throw new Error "value: #{_value}" unless typeof _value == 'object' && _value != null && _value.hasOwnProperty('$ds_ref')
          throw new Error "propName: #{_propName}" unless typeof _propName == 'string'
          throw new Error "Too many args" unless arguments.length <= 3

          unless _value.$ds_scope == null
            setterResult.currentPropName = propName
            setterResult.result.error 'dsd.documentHasWrongDSScope'
            setterResult.currentPropName = null
            setterResult.result.throwIfError()
            return

          _value.$addRef _owner
