utils
==============================

    {Result, utils: {checkItemName, deepClone, combineMsg, sortedMap}} = require '../src'

    focusOnCheck = ""
    check = (itName, itBody) -> (if focusOnCheck == itName then fit else it) itName, itBody; return

    describe '002_utils_checkItemName:', ->

checkItemName
------------------------------

Чтобы избежать проблем с именование документов, полей, enum-значений в различных внених системах (sequelizejs,
angularjs, postgres ...), в DSCommon3 вводим ограничение, что имя любого именованного элемента может состояить
только из букв и цифр, и обязательно начаниться с маленькой буквы.  Имя, в том числе, не можем содеражить пробелы.


      check "correctName", ->

        expect(checkItemName 'correctName').toBe true

      check "WrongName", ->

        expect(checkItemName 'WrongName').toBe false

      check "with space", ->

        expect(checkItemName 'with space').toBe false

      check "withDigits123", ->

        expect(checkItemName 'withDigits123').toBe true

      check "3StartingWithDigits", ->

        expect(checkItemName '3StartingWithDigits').toBe false
