config
==============================

    {Result,
    config: {compile: compileConfig, link: linkConfig, unlink: unlinkConfig},
    utils: {deepClone, prettyPrint}} = require '../src'

    processCustomValidate = require '../src/validate/processCustomValidate'

    focusOnCheck = ''
    check = (itName, itBody) -> (if focusOnCheck == itName then fit else it) itName, itBody; return

    describe '100_check_editValidate', ->

      check 'general', ->

        res = compileConfig (result = new Result),
          udtypes:
            'traskoCrm.photo':
              extra: {
                name1C: 'Photo'
              },
              type: 'text'
            'traskoCrm.id1C':
              extra:
                name1C: 'ID_1C'
                label: '1C ID'
                description: 'Required. Identifier of the site account in 1C. A parameter\nassigned automatically inside 1C, of the form:\nb0d4ce5d-2757-4699-948c-cfa72ba94f86'
              type: 'string'
              length: 36
            'trascoCrm.priorityCommunicationChannel':
              extra: {
                name1C: 'PriorityCommunicationChannel',
                label: 'Priority communication channel',
                description: '
                  Phone
                  EmailAddress
                '
              },
              type: 'enum',
              enum: [{
                name: 'email',
                extra: {
                  value1C: 'EmailAddress',
                  label: 'Email',
                  labelEn: 'Email'
                }
              }, {
                name: 'phone',
                extra: {
                  value1C: 'Phone',
                  label: 'Phone',
                  labelEn: 'Phone'
                }
              }]
            phone:
              type: 'string'
              length: 15
              regexp: /^\+?[\s\d\(\)-]*$/
            email:
              type: 'string'
              length: 320
              regexp: /^((?:[a-z0-9!#$%&'*+/=?^_'{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_'{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\]))?$/i
          docs: Contact:
            extra: {
              label: 'Contact',
              labelEn: 'Contact'
            },
            fields: {
              contactPersonId: {
                extra: {
                  name1C: 'ContactPersonId',
                  label: 'Contact person identifier',
                  description: 'Required. Identifier of the contact person in 1C. A parameter assigned automatically inside 1C of the form:\nb0d4ce5d-2757-4699-948c-cfa72ba94f86'
                },
                type: 'traskoCrm.id1C'
              },
              #              photo: {
              #                extra: {
              #                  name1C: 'Photo',
              #              label: 'Photo',
              #                description: 'Photo file, passed as binary data'
              #                },
              #                tags: 'ui.cardSection1, ui.newContactPerson',
              #                type: 'traskoCrm.photo',
              #                validate: 'base64FileSize(3)',
              #                null: true
              #              },
              contactName: {
                extra: {
                  name1C: 'ContactName',
                  label: 'Full name',
                  description: 'Required. Last name, First name, Patronymic of the user submitting the request.\nFor requests created from the personal account it is filled in automatically based on the account data (may be corrected). In other cases it is entered manually'
                },
                tags: 'ui.cardSection1',
                type: 'string(4096)',
                required: true
              },
              email: {
                extra: {
                  name1C: 'Email',
                  label: 'Email address',
                  description: 'Required. Email on the request form.'
                },
                tags: 'ui.cardSection1',
                type: 'email',
                required: true
              },
              phone: {
                extra: {
                  name1C: 'Phone',
                  label: 'Phone',
                  description: 'Phone number in the format: 7 (968) 342-12-67'
                },
                tags: 'ui.cardSection1',
                type: 'phone'
              },
              mobile: {
                extra: {
                  name1C: 'Mobile',
                  label: 'Mobile phone',
                  description: 'Phone number in the format: 7 (968) 342-12-67'
                },
                tags: 'ui.cardSection1',
                type: 'phone'
              },
              position: {
                extra: {
                  name1C: 'Position',
                  label: 'Position',
                  description: ''
                },
                tags: 'ui.cardSection1',
                type: 'string(4096)'
              },
              priorityCommunicationChannel: {
                extra: {
                  name1C: 'PriorityCommunicationChannel',
                  label: 'Priority communication channel',
                  description: 'Dropdown list: Phone, Email, Social network'
                },
                tags: 'ui.cardSection1',
                null: false,
                init: 'phone',
                type: 'trascoCrm.priorityCommunicationChannel',
              },
              photoExtension: {
                extra: {
                  name1C: 'PhotoExtension',
                  label: 'Photo file extension',
                  description: 'File extension of the photo, as a hint for the browser. For example “jpg”, “png”'
                },
                type: 'string(4096)',
                null: true
              }
            }

        expect(result.messages).toEqual []

        unlinkedConfig = unlinkConfig res

        linkedConfig = linkConfig unlinkedConfig

        res = linkedConfig.docs['doc.Contact'].$$editValidate {
          contactPersonId: "5a1a26a8-cb3d-11ea-8184-00155d0a5000"
          # photo: null,
          contactName: "Anna Knyazeva"
          email: "knyazeva"
          phone: "222"
          mobile: "333"
          position: "222"
          priorityCommunicationChannel: "email"
          photoExtension: null
          $$touched:
            priorityCommunicationChannel: true
            email: true
        }, beforeAction: false

        expect(res).toEqual
          save: false
          goodForAction: false
          messages:
            email:
              type: 'error'
              path: 'email'
              code: 'validate.invalidValue'
              value: 'knyazeva'
              regexp: /^((?:[a-z0-9!#$%&'*+/=?^_'{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_'{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\]))?$/i.toString()

        res = linkedConfig.docs['doc.Contact'].$$editValidate {
          contactPersonId: "5a1a26a8-cb3d-11ea-8184-00155d0a5000"
          # photo: null,
          contactName: "Anna Knyazeva"
          email: "knyazeva2"
          phone: "222"
          mobile: "333"
          position: "222"
          priorityCommunicationChannel: "email"
          photoExtension: null
          $$touched:
            priorityCommunicationChannel: true
            email: true
        }, beforeAction: false

        expect(res).toEqual
          save: false
          goodForAction: false
          messages:
            email:
              type: 'error'
              path: 'email'
              code: 'validate.invalidValue'
              value: 'knyazeva2'
              regexp: /^((?:[a-z0-9!#$%&'*+/=?^_'{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_'{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\]))?$/i.toString()
