result path
==============================

    {Result, utils: {err: {_argError}}} = require '../src'

    focusOnCheck = ""
    check = (itName, itBody) -> (if focusOnCheck == itName then fit else it) itName, itBody; return

    describe '012_result_path:', ->

It has become clear that errors do not have the complex concept of context, for which one would need the ability to store
various information.  All that is really needed is the path to the element the error relates to.  And literally three
elements are enough for that:
* the key, if we are talking about an object (map),
* the index, if we are talking about an array
* the element name, if we are talking about a sortedMap, for which the same structure can be represented as an array,
an object, or simply as a string with elements separated by a comma

      check "Result.prop", ->

To support such a structure we keep the same idea as with the result object: there should be an array of methods - context, which
at the time of writing the message are used to obtain the path to the element.

        propContext = Result.prop 'propName'

        expect(typeof propContext).toBe 'function'

        expect(propContext '').toBe 'propName'

        expect(propContext 'rootContext').toBe 'rootContext.propName'

Several properties can be combined into one function

        expect((Result.prop 'propName') '').toBe 'propName'

        expect((Result.prop 'a', Result.prop 'propName') '').toBe 'propName.a'

Result.item adds the index in square brackets

      check "Result.index", ->

        propContext = Result.index 10

        expect(typeof propContext).toBe 'function'

        expect(propContext '').toBe '[10]'

        expect(propContext 'rootContext').toBe 'rootContext[10]'

        expect((Result.index 20) '').sameStructure '[20]'

        expect((Result.index 20, Result.prop 'config') '').sameStructure 'config[20]'

Result.name adds the element name (name) in square brackets

#      check "Result.item", ->
#
#        propContext = Result.item 'field1'
#
#        expect(typeof propContext).toBe 'function'
#
#        expect(propContext '').toBe '.field1'
#
#        expect(propContext 'rootContext').toBe 'rootContext.field1'
#
#        expect((Result.item 'field1') '').sameStructure '.field1'
#
#        expect((Result.item 'field1', Result.prop 'config') '').sameStructure 'config.field1'

      check "complex", ->

        context =
          Result.index 10,
          Result.prop 'update',
          Result.prop 'opened',
          Result.prop 'states',
          Result.prop 'fieldA',
          Result.prop 'fields',
          Result.prop 'Doc1',
          Result.prop 'docs'

The path is assembled as sequential calls of the ctx functions

        path = context ''

        expect(path).toBe 'docs.Doc1.fields.fieldA.states.opened.update[10]'
