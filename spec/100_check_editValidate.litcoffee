config
==============================

    {Result,
    config: {compile: compileConfig, link: linkConfig, unlink: unlinkConfig},
    utils: {deepClone, prettyPrint}} = require '../src'

    processCustomValidate = require '../src/validate/processCustomValidate'

    focusOnCheck = 'general'
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
                label: '1С ID'
                description: 'Обязательный. Идентификатор учетной записи сайта в 1С. Параметр,\nприсваиваемый автоматически внутри 1С вида:\nb0d4ce5d-2757-4699-948c-cfa72ba94f86'
              type: 'string'
              length: 36
            'trascoCrm.priorityCommunicationChannel':
              extra: {
                name1C: 'PriorityCommunicationChannel',
                label: 'Приоритетный канал связи',
                description: '
                  Телефон
                  АдресЭлектроннойПочты
                '
              },
              type: 'enum',
              enum: [{
                name: 'email',
                extra: {
                  value1C: 'АдресЭлектроннойПочты',
                  label: 'Email',
                  labelEn: 'Email'
                }
              }, {
                name: 'phone',
                extra: {
                  value1C: 'Телефон',
                  label: 'Телефон',
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
              label: 'Контакт',
              labelEn: 'Contact'
            },
            fields: {
              contactPersonId: {
                extra: {
                  name1C: 'ContactPersonId',
                  label: 'Идентификатор контактного лица',
                  description: 'Обязательный. Идентификатор контактного лица в 1С. Параметр, присваиваемый автоматически внутри 1С вида:\nb0d4ce5d-2757-4699-948c-cfa72ba94f86'
                },
                type: 'traskoCrm.id1C'
              },
              #              photo: {
              #                extra: {
              #                  name1C: 'Photo',
              #                  label: 'Фото',
              #                  description: 'Файл с фотографией, передаваемый в форме двоичных данных'
              #                },
              #                tags: 'ui.cardSection1, ui.newContactPerson',
              #                type: 'traskoCrm.photo',
              #                validate: 'base64FileSize(3)',
              #                null: true
              #              },
              contactName: {
                extra: {
                  name1C: 'ContactName',
                  label: 'ФИО',
                  description: 'Обязательный. Фамилия. Имя, Отчество пользователя, оформляющего обращение.\nДля обращений, создаваемых из личного кабинета заполняется автоматически на основании учетных данных (может быть скорректирован). В остальных случаях задается вручную'
                },
                tags: 'ui.cardSection1',
                type: 'string(4096)',
                required: true
              },
              email: {
                extra: {
                  name1C: 'Email',
                  label: 'Адрес электронной почты',
                  description: 'Обязательный. Электронная почта на форме обращения.'
                },
                tags: 'ui.cardSection1',
                type: 'email',
                required: true
              },
              phone: {
                extra: {
                  name1C: 'Phone',
                  label: 'Телефон',
                  description: 'Номер телефона в формате: 7 (968) 342-12-67'
                },
                tags: 'ui.cardSection1',
                type: 'phone'
              },
              mobile: {
                extra: {
                  name1C: 'Mobile',
                  label: 'Мобильный телефон',
                  description: 'Номер телефона в формате: 7 (968) 342-12-67'
                },
                tags: 'ui.cardSection1',
                type: 'phone'
              },
              position: {
                extra: {
                  name1C: 'Position',
                  label: 'Должность',
                  description: ''
                },
                tags: 'ui.cardSection1',
                type: 'string(4096)'
              },
              priorityCommunicationChannel: {
                extra: {
                  name1C: 'PriorityCommunicationChannel',
                  label: 'Приоритетный канал связи',
                  description: 'Выпадающий список: Телефон, Email, Соцсеть'
                },
                tags: 'ui.cardSection1',
                null: false,
                init: 'phone',
                type: 'trascoCrm.priorityCommunicationChannel',
              },
              photoExtension: {
                extra: {
                  name1C: 'PhotoExtension',
                  label: 'Расширение файла c фотографией',
                  description: 'Расширение файла с фотографией для подсказки браузеру. Например “jpg”, “png”'
                },
                type: 'string(4096)',
                null: true
              }
            }

        expect(result.messages).toEqual []

        unlinkedConfig = unlinkConfig res

        linkedConfig = linkConfig unlinkedConfig

        validate = linkedConfig.docs['doc.Contact'].$$editValidateBuilder()

        res = validate {
          contactPersonId: "5a1a26a8-cb3d-11ea-8184-00155d0a5000"
          # photo: null,
          contactName: "Анна Князева"
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

        res = validate {
          contactPersonId: "5a1a26a8-cb3d-11ea-8184-00155d0a5000"
          # photo: null,
          contactName: "Анна Князева"
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
