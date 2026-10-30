Document type description
==============================

A document type description is just a json structure that is loaded from a file via require()

    module.exports =

Document type name
------------------------------

The document type name is the file name.  After loading into memory the name property will be added

Fields
------------------------------

List of document fields, in the preferred display order

      fields:

The field name is the key in fields.  After loading this name will be duplicated in the name property

        field1:

The field type is described by the attributes for describing the field type: type, udttype, length, ...

          type: 'string'
          lenght: '20'

A field can have tags, which are used for working with groups of fields in state/view, state/update, as well as in the permission system

          tags: ['user', 'admin', 'tag3']

A couple more fields

        field2:

Using a user defined type, which will be described in a separate file

          udtype: 'name'

Tags can also be written on a single line

          tags: 'user,admin'

        field3:

          type: 'structure'

Structure fields, the same fields as the top-level fields of the document

          fields:
            a:
              type: 'int'
            b:
              type: 'date'

        field4:

For a reference to a document, we write the type in a string

          ref: 'docSimple'

Actions
------------------------------

      actions:

The action name is the key in actions.  After loading this name will be duplicated in the name property

        action1:

Inside we define the code.  The code can be for different contexts.  '' - the default context

          '': -> return

Code in the 'server' context - will run only on the server

          'server': -> return

An action can be without code

        action2: true

If there is only code that must run everywhere, then it can be written briefly

        action3: -> return

States
------------------------------

      states:

The state name is the key in states.  After loading this name will be duplicated in the name property

        opened:

After that, view and update can be either an array with a list of fields/tags or a string with a comma-separated list

          view: 'field1,field2'

When writing field names, expressions over tags can be used.  What may participate:
* <name> - group name
* ! - negated group
* - - all fields on the left, except the fields on the right
* +/, - union of the fields on the left and on the right
* (/) - parentheses for grouping operations

          update: ['#all-#user', 'field2']

          transitions:

Unlike DSCommon2, there is no need to declare actions for which there is no need to write processing code.  In other words, the
fact that close is used in transitions automatically adds close to actions.

            close: 'closed'

        closed:

          view: '#all'

If the view or update attribute is omitted, it is assumed to be an empty list

          transitions:

            open:

              '': 'opened'

A state transition (transition) can be conditional.  lock is a condition

              'lock': true

Conditions
------------------------------

      conditions:

        lock:

For conditions that cannot be verified on the spot, a default value can be specified.  If no default
is specified, it is assumed that default: false

          default: true

Method returning true/false

          fn: -> @get 'lock'

