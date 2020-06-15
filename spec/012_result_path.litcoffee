result path
==============================

    {Result, utils: {err: {_argError}}} = require '../src'

    focusOnCheck = ""
    check = (itName, itBody) -> (if focusOnCheck == itName then fit else it) itName, itBody; return

    describe '012_result_path:', ->

Стало понятно, что у ошибок не бывает сложного понятия context, для которого нужно иметь возможность сохранять
разнообразную информацию.  Всё что реально нужно, это путь (path) к элементу, к которому относится ошибка.  И для этого
достаточно буквально трех элементов:
* ключ, если речь идет об объекте (map),
* индекс, если речь идет о массиве
* имя элемента, если речь идет о sortedMap, для которого одна и та же структура может быть представлена и как массив,
как объект или просто как строка с элементами разделенными запятой

      check "Result.prop", ->

Для поддержания такой структуры оставляем ту же идею, что у объекта result, должен быть массив методов - context, которые
в момент записи сообщения, используются для получения пути к элементу.

        propContext = Result.prop 'propName'

        expect(typeof propContext).toBe 'function'

        expect(propContext '').toBe 'propName'

        expect(propContext 'rootContext').toBe 'rootContext.propName'

Можно объединять несколько свойств в одну функцию

        expect((Result.prop 'propName') '').toBe 'propName'

        expect((Result.prop 'a', Result.prop 'propName') '').toBe 'propName.a'

Result.item добавляет индекс в квадратных скобках

      check "Result.index", ->

        propContext = Result.index 10

        expect(typeof propContext).toBe 'function'

        expect(propContext '').toBe '[10]'

        expect(propContext 'rootContext').toBe 'rootContext[10]'

        expect((Result.index 20) '').sameStructure '[20]'

        expect((Result.index 20, Result.prop 'config') '').sameStructure 'config[20]'

Result.name добавляет имя (name) элемента в квадратных скобках

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

Собираем path, как последовательные вызовы функций ctx

        path = context ''

        expect(path).toBe 'docs.Doc1.fields.fieldA.states.opened.update[10]'
