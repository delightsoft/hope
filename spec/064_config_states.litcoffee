config.docs.Doc.states
==============================

    {Result,
    config: {compile: {_processStates: processStates, _processFields: processFields, _processActions: processActions}},
    utils: {deepClone}} = require '../src'

    focusOnCheck = ''
    check = (itName, itBody) -> (if focusOnCheck == itName then fit else it) itName, itBody; return

    describe "064_config_states", ->

general
------------------------------

      check "general", ->

        doc =
          name: 'Doc1'
          $$src:
            fields:
              fld1: type: 'int', tags: 'tag1'
              fld2: type: 'string(20)', tags: 'tag1, tag2'
              fld3:
                fields:
                  a: type: 'json', tags: 'tag2'
                  b: type: 'timestamp'
            actions:
              open: {}
              close: {}
            states:
              opened:
                view: 'fld1, fld2'
                update: 'fld1'
                transitions:
                  close: 'closed'
              closed:
                view: '#tag1 - #tag2'
                update: '#tag2'
                transitions:
                  open: 'opened'

        $$src = deepClone doc.$$src

        (res = {}).fields = processFields (result = new Result), doc, {}, 'fields'
        res.actions = processActions (result = new Result), doc, true
        res.states = processStates (result = new Result), doc, res.fields, res.actions unless result.isError

        expect(result.messages).toEqual []

Исходный документ не изменяется

        expect(doc.$$src).sameStructure $$src

      check "error: general", ->

        doc =
          name: 'Doc1'
          $$src:
            fields:
              fld1: type: 'int', tags: 'tag1'
              fld2: type: 'string(20)', tags: 'tag1, tag2'
              fld3:
                fields:
                  a: type: 'json', tags: 'tag2'
                  b: type: 'timestamp'
            actions:
              open: {}
              close: {}
            states:
              opened:
                view: 'fld1, fld2, notAField'
                update: 'fld1'
                transitions:
                  close: 'closed'
                  notAnAction: 'tralala'
              closed:
                view: '#tag1 - #tag2 + #invalidTag'
                update: '#tag2'
                transitions:
                  open: 'opened'

        (res = {}).fields = processFields (result = new Result), doc, {}, 'fields', true
        res.actions = processActions (result = new Result), doc, true
        res.states = processStates (result = new Result), doc, res.fields, res.actions unless result.isError

        expect(result.messages).sameStructure [
          {type: 'error', path: 'states.opened.view', code: 'dsc.unknownItem', expr: 'fld1, fld2, notAField', value: 'notAField', position: 12 }
          {type: 'error', path: 'states.opened.transitions.notAnAction', code: 'dsc.unknownAction', value: 'notAnAction' }
          {type: 'error', path: 'states.opened.transitions.notAnAction.next', code: 'dsc.unknownState', value: 'tralala' }
          {type: 'error', path: 'states.closed.view', code: 'dsc.unknownTag', expr: '#tag1 - #tag2 + #invalidTag', value: 'invalidTag', position: 16 }
        ]
