DSScopeStub
==============================

    module.exports =

The DSScope interface is needed for DSDocument to work.

There are three implementations of DSScope:
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

The find method asynchronously loads the document with the specified ID.  After loading, the callback is invoked with the parameters (error, doc),
where error, if not null, is an object of class Result, necessarily with isError == true.

        find: (@_owner, @_docId, @_cb) ->

          @_findArgs.push {owner: @_owner, docId: @_docId, cb: @_cb}

          throw new Error "owner: #{@_owner}" unless typeof @_owner == 'object' && @_owner != null && @_owner.hasOwnProperty('$ds_ref')
          throw new Error "docId: #{@_docId}" unless typeof @_docId == 'string' && @_docId.indexOf('@') >= 0
          throw new Error "cb: #{@_cb}" unless typeof @_cb == 'function'
          throw new Error "Too many args" unless arguments.length <= 3
          @_wait = true

The find method returns an unwait function that allows giving up on receiving the result

          => @_wait = false; return

When a document is assigned to propDoc in the editable version of the document, the document
- is checked to make sure it belongs to the correct dsscope
- possibly replaced with the correct version (original or editable) of the document

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
