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
              open: ->
              close: ->
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

        (res = {}).fields = processFields (result = new Result), doc, {}, 'fields', true
        res.actions = processActions (result = new Result), doc, true
        res.states = processStates (result = new Result), doc, res.fields, res.actions

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
              open: ->
              close: ->
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
        res.states = processStates (result = new Result), doc, res.fields, res.actions

        expect(result.messages).sameStructure [
          {type: 'error', path: 'states.opened.view', code: 'dsc.unknownItem', value: 'notAField', position: 12 }
          {type: 'error', path: 'states.opened.transitions.notAnAction', code: 'dsc.unknownAction', value: 'notAnAction' }
          {type: 'error', path: 'states.opened.transitions.notAnAction.next', code: 'dsc.unknownState', value: 'tralala' }
          {type: 'error', path: 'states.closed.view', code: 'dsc.unknownTag', value: 'invalidTag', position: 16 }
        ]

//      check "general", ->
//
//        doc =
//          name: 'Doc1'
//          states:
//            opened:
//              view: '#all'
//              update: ''
//              transitions:
//                open: ''
//
//        doc =
//          name: doc.name
//          $$src: doc
//
//        processStates (result = new Result), doc
//
//        expect(result.messages).sameStructure []
//
//        delete doc.$$src
//
//        expect(doc).sameStructure
//          name: 'Doc1'
//          states: states =
//            opened: stateOpened =
//              name: 'opened'
//              view: '#all'
//              update: ''
//              transitions:
//                open: transitionOpen =
//                  name: 'open'
//                  next: ''
//                $$list: [transitionOpen]
//            $$list: [stateOpened]
//
//missing props
//------------------------------
//
//      check "'states' is missing", ->
//
//        doc = name: 'Doc1'
//
//        doc = name: doc.name, $$src: doc
//
//        processStates (new Result (result = new Result)), doc
//
//        expect(result.messages).sameStructure []
//
//        delete doc.$$src
//
//        expect(doc).sameStructure
//
//          name: 'Doc1'
//
//          states: {$$list: []}
//
//      check "error: state.transition.next missing", ->
//
//        doc =
//
//          name: 'Doc1'
//
//          states:
//
//            opened:
//
//              transitions:
//
//                close: {}
//
//        doc = name: doc.name, $$src: doc
//
//        processStates (new Result (result = new Result)), doc
//
//        expect(result.messages).sameStructure [
//          {type: 'error', path: 'states[opened].transitions[close]', code: 'dsc.missingProp', value: 'next'}
//        ]
//
//wrong values
//------------------------------
//
//      for errValue in [undefined, null, true, false, 12, {}]
//
//        do (errValue) -> check "error: wrong state.view value: #{errValue}", ->
//
//          doc =
//
//            name: 'Doc1'
//
//            states:
//
//              opened:
//
//                view: errValue
//
//          doc = name: doc.name, $$src: doc
//
//          processStates (new Result (result = new Result)), doc
//
//          expect(result.messages).sameStructure [
//            {type: 'error', path: 'states[opened].view', code: 'dsc.invalidValue', value: errValue}
//          ]
//
//      for errValue in [undefined, null, true, false, 12, {}]
//
//        do (errValue) -> check "error: wrong state.update value: #{errValue}", ->
//
//          doc =
//
//            name: 'Doc1'
//
//            states:
//
//              opened:
//
//                update: errValue
//
//          doc = name: doc.name, $$src: doc
//
//          processStates (new Result (result = new Result)), doc
//
//          expect(result.messages).sameStructure [
//            {type: 'error', path: 'states[opened].update', code: 'dsc.invalidValue', value: errValue}
//          ]
//
//      for errValue in [undefined, null, true, false, 12, [], {}]
//
//        do (errValue) -> check "error: wrong state.transition.next value: #{errValue}", ->
//
//          doc =
//
//            name: 'Doc1'
//
//            states:
//
//              opened:
//
//                transitions:
//
//                  close:
//
//                    next: errValue
//
//          doc = name: doc.name, $$src: doc
//
//          processStates (new Result (result = new Result)), doc
//
//          expect(result.messages).sameStructure [
//            {type: 'error', path: 'states[opened].transitions[close].next', code: 'dsc.invalidValue', value: errValue}
//          ]
//
//      for errValue in [undefined, null, true, false, 12, []]
//
//        do (errValue) -> check "error: wrong state.transition inline value: #{errValue}", ->
//
//          doc =
//
//            name: 'Doc1'
//
//            states:
//
//              opened:
//
//                transitions:
//
//                  close: errValue
//
//          doc = name: doc.name, $$src: doc
//
//          processStates (new Result (result = new Result)), doc
//
//          expect(result.messages).sameStructure [
//            {type: 'error', path: 'states[opened].transitions.close', code: 'dsc.invalidValue', value: errValue}
//          ]
//
//unexpected props
//------------------------------
//
//      check "error: unexpect prop in state", ->
//
//        doc =
//
//          name: 'Doc1'
//
//          states:
//
//            opened:
//
//              unexpectedProp: {}
//
//              transitions:
//
//                close:
//
//                  next: 'closed'
//
//        doc = name: doc.name, $$src: doc
//
//        processStates (new Result (result = new Result)), doc
//
//        expect(result.messages).sameStructure [
//          {type: 'error', path: 'states[opened]', code: 'dsc.unexpectedProp', value: 'unexpectedProp'}
//        ]
//
//      check "error: unexpect prop in state[stateName].transitions[transitionName]", ->
//
//        doc =
//
//          name: 'Doc1'
//
//          states:
//
//            opened:
//
//
//              transitions:
//
//                close:
//
//                  next: 'closed'
//
//                  unexpectedProp: {}
//
//        doc = name: doc.name, $$src: doc
//
//        processStates (new Result (result = new Result)), doc
//
//        expect(result.messages).sameStructure [
//          {type: 'error', path: 'states[opened].transitions[close]', code: 'dsc.unexpectedProp', value: 'unexpectedProp'}
//        ]
