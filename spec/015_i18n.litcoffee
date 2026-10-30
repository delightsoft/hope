I18n (Internationalization)
==============================

The general principle of localization is that a message code corresponds to a function in config.i18n that creates the message.

    {Result, i18n, utils} = require '../src'

    focusOnCheck = ""
    check = (itName, itBody) -> (if focusOnCheck == itName then fit else it) itName, itBody; return

    describe '015_i18n:', ->

      beforeEach ->

Messages are a flatMap

        messages =

          test:

The message test.messageA without arguments

            messageA: @f3 = -> "Message A"

The message test.messageB with an argument

            messageB: @f4 = (args) -> "Message B. Value: #{args.value}"

A message in the form of a simple string

            messageC: @s1 = 'Simple Message'

Or even numbers

            messageD: @n1 = 121

Before using the internationalization data, the i18n.link method must be executed

        @messages = i18n.link (@result = new Result), messages

The i18n.link method rebuilds the messages from a hierarchical structure into a flat map.  At the same time, warnings
will be issued about missing parts

      check "A", ->

        expect(@messages).sameStructure
          'test.messageA': @f3
          'test.messageB': @f4
          'test.messageC': @s1
          'test.messageD': @n1

The i18n.format method formats messages
            
      check "B", ->

If the message exists in the localization, we get the localized message

        expect(i18n.format @messages, code: 'test.messageA').toBe 'Message A'

If the message exists in the localization and contains parameters, we get the localized message with parameters

        expect(i18n.format @messages, code: 'test.messageB', value: '123').toBe 'Message B. Value: 123'

If the message localization is just a string, we get that string as the result

        expect(i18n.format @messages, code: 'test.messageC').toBe 'Simple Message'

If the message localization is neither a function nor a string, we get the localization value in string form

        expect(i18n.format @messages, code: 'test.messageD').toBe '121'

If the message is NOT in the localization, then the message name is kept

        expect(i18n.format @messages, code: 'test.messageQ').toBe 'test.messageQ'

If the message is NOT in the localization, and it has parameters, then the message name is kept and the parameter is appended to the end
of the message as JSON.

        expect(i18n.format @messages, code: 'test.messageF', value: '123').toBe 'test.messageF{"value":"123"}'

The message code must match the structure of the localization

      check "C", ->

If Test is with a capital letter, the variant where test is lowercase is no longer found

        expect(i18n.format @messages, code: 'Test.messageA').toBe 'Test.messageA'

The same for MessageA with a capital letter

        expect(i18n.format @messages, code: 'test.MessageA').toBe 'test.MessageA'

If the path to the message contains additional steps, then no intermediate variant is found either

        expect(i18n.format @messages, code: 'test.messageA.extra').toBe 'test.messageA.extra'

A message can contain a context, which is formatted by the same rules as the main message, only
the method is selected from config.i18n.contexts

      check "D", ->

        expect(i18n.format @messages, path: 'config', code: 'test.messageA')
        .toBe "config: Message A"

        expect(i18n.format @messages, path: 'config', code: 'test.messageB', value: '123')
        .toBe "config: Message B. Value: 123"

Formatting can be done without an i18n collection.  Then the format works as if the localization were never found

      check "E", ->

        expect(i18n.format undefined, code: 'test.messageA').toBe 'test.messageA'

If the message exists in the localization and contains parameters, we get the localized message with parameters

        expect(i18n.format null, code: 'test.messageB', value: 123).toBe 'test.messageB{"value":123}'

If the message contains a path, then it is added to the message without localization

      check "F", ->

        expect(i18n.format null, path: 'a[1]', code: 'test.messageB', value: 123)
        .toBe "a[1]: test.messageB{\"value\":123}"