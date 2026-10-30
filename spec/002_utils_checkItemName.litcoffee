utils
==============================

    {Result, utils: {checkItemName, deepClone, combineMsg, sortedMap}} = require '../src'

    focusOnCheck = ""
    check = (itName, itBody) -> (if focusOnCheck == itName then fit else it) itName, itBody; return

    describe '002_utils_checkItemName:', ->

checkItemName
------------------------------

To avoid problems with naming documents, fields, and enum values in various external systems (sequelizejs,
angularjs, postgres ...), DSCommon3 introduces a restriction that the name of any named element may consist
only of letters and digits, and must necessarily begin with a lowercase letter. Also, the name cannot contain spaces.


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
