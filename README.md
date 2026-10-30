# Hope.js (DSCommon)

A declarative document-model framework for JavaScript data layers, written in CoffeeScript 2.
The npm package name is **`dscommon3`**; the library calls itself **DSCommon** internally.

Instead of scattering ad-hoc schema handling, ACL logic and validation all over an application,
you declare your business domain once — plain JSON/JS structures — and the library compiles it
into an immutable, deeply frozen runtime config, attaching generated methods to every collection
of fields:

- document construction: `$$new`
- fill / read / merge: `$$fix`, `$$get`, `$$set`, `$$update`, `$$wasTouched`
- per-user permission masks: `$$access`, `$$docAccess`, `$$rights`
- full validation: `$$validate`, `$$editValidate`, with `$$touched` change tracking
- tag-based field-group queries: `$$calc` with a small expression language (`'#all-#system'`)

A convention is enforced across the whole codebase: functions *throw* on programmer mistakes
(invalid arguments, wrong option names) but *report* data mistakes as messages accumulated in a
universal `Result` object, so compilers and validators can collect full, precisely located
reports instead of failing on the first issue.

Because the compiled config is serializable with `config.unlink()`, the same model can be built
on a server and shipped to a browser (the helpers like `$$vueDebugWatchBuilder` and
`$$editValidate` are designed for a Vue.js client).

## Top-level API

```coffee
{Result, BitArray, Reporter, loader, i18n, utils, types, tags,
 config, sortedMap, flatMap, compareStructures} = require '../src'
```

| Export | Description |
| --------------- | ------------------------------------------------------------ |
| `Result` | Message/error accumulator class (see below) with path helpers `Result.prop` / `Result.index` |
| `BitArray` | Compact bitmask (32 bits per array cell) over a collection's `$$list` |
| `Reporter` | Console-oriented companion to `Result` |
| `loader` | Loads a project description directory (`docs`, `types`, `rights`, `api`, `validators`) |
| `i18n` | `{link, format}` — message localization for `Result` messages |
| `utils` | `err` helpers, `flatTree`, `deepClone`/`lightClone`, name validators, `prettyPrint`, `extend`, `lightStack` |
| `types` | `{compile}` — single field-type compiler |
| `tags` | `{compile, calc}` — tag compilation and the tag-expression language |
| `config` | `{compile, link, unlink, messages, actionsIndex}` — the model pipeline |
| `sortedMap` / `flatMap` | Name-keyed ordered map builders (flat map supports nested subitems) |
| `compareStructures` | Deep structural differ used to compare data structures |

## The `Result` object

Every compiler, validator and helper works with a `Result`:

```coffee
result = new Result

result.error 'someCode', value: 10   # sets result.isError = true
result.warn 'someWarning'
result.info pathFunc, 'infoMsg', value: 10

result.context Result.prop('doc.DocA').prop('fields'), ->
    # nested paths accumulate; isError is scoped and restored on exit
    result.error 'dsc.missingProp'
```

- Each message is a plain object: `{code, path?, type?, ...args}`.
  `type` is `'error' | 'warn'` (omitted for `info`).
- `Result.prop(name, pathFunc?)` appends `.name` (or `['name.with.dots']`) and returns a curried
  path function, so code always reads `result.context Result.prop(name), -> ...`.
- `Result.index(i, pathFunc?)` appends `[i]`.
- `add(result)` merges another Result's messages; `reset()` clears them;
  `throwIfError(page)` throws `err.code = 'dsc.result'` when `isError`.
- `isResult(x)` identifies a Result/Reporter by duck-typing (deliberately not `instanceof`).

Message codes are namespaced:

- `dsc.*` — compilation errors, e.g. `dsc.unexpectedProp`, `dsc.duplicatedName`,
  `dsc.invalidName`, `dsc.cycledUdtypes`, `dsc.missingFile`, `dsc.invalidExpression`.
  Human templates are in `config.messages` (`src/config/_messages.coffee`).
- `validate.*` — runtime field-validation errors: `validate.invalidValue`, `validate.unknownField`,
  `validate.requiredField`, `validate.tooLong`, `validate.tooBig`, etc.

### i18n

```coffee
messages = i18n.link result, dsc: (msg) -> ...   # functions may build message text
i18n.format messages, code: 'dsc.missingProp', value: 'lang.prop'
```

`i18n.link` flattens an arbitrary i18n tree into a flat code-to-entry map.
`i18n.format` renders a message: if the table holds a function for `message.code`, it is called;
if it holds a string template, it is used verbatim; otherwise the code plus JSON-serialized
arguments are returned. `Reporter` uses the same mechanism to print `Result` reports; override
its `_print(type, text)` for custom output.

### Loading a project

```coffee
result = new Result
loader(result, path.resolve __dirname, '../samples').then (sourceConfig) ->
    # sourceConfig = { docs, udtypes?, rights?, api?, validators? }
```

`loader` reads exactly these files from the directory: `docs` (required), and optionally
`types`, `rights`, `api`, `validators`. Missing optional files produce a `dsc.noSuchFile`
warning; a missing `docs` produces `dsc.missingFile`.

## The declarative model

```coffee
config =
  udtypes:                    # user-defined types
    name: type: 'string(100)'
    intBase: type: 'int'
  docs:                       # document definitions
    docSimple:
      fields:                 # preferred display order
        name:  udtype: 'name'
        age:   type: 'int(3)', tags: 'user'
        addr:  type: 'structure', fields: {...}
        link:  ref: 'docSimple'      # reference to another document
      actions:
        close: {}                    # a no-code action
        open: (->)                   # shorthand for default-context code
        list:
          arguments: { x: type: 'int', tags: 'a' }
          result:    { r: type: 'boolean' }
      states:
        opened:
          view:   'field1,field2'
          update: ['#all-#user', 'field2']
          transitions:
            close: 'closed'      # used in transitions => action auto-registered
        closed:
          view: '#all'
          transitions:
            open: { '': 'opened', 'lock': true }   # conditional transition
      conditions:
        lock: default: true, fn: -> @get 'lock'
  api:                        # API surface with arguments/result schemas
    api1: methods: methodA: arguments: {...}, result: {...}
```

`config.compile(result, sourceConfig, noSystemItems?)` transforms this into the internal
representation: named, alphabetically ordered, namespaced maps (`docSimple` lands in the
default `doc.` namespace, i.e. `docs['doc.DocA']`), compiles every field type, builds tags,
adds system fields (`id`, `rev`, `state`, ... ) and system actions (`create`, `retrieve`,
`update`, `delete`, `restore`) unless told otherwise.

`config.link(config, methods?, opts?)` then attaches all runtime helpers, compiles tag
expressions of view/update masks etc., and deep-freezes everything into an immutable config.
User code can be injected via `links = {rights, docs: {DocA: {rights, validate}}, api: ...}`.

`config.unlink(config)` is the inverse of `link`: it produces a plain, JSON-friendly structure
(BitArrays become integer masks, functions are dropped) that can be sent to the browser and
relinked with `config.link(...)` there.

### Tag expressions

Field groups are addressed with tags, e.g. `tags: 'user,admin'`. View/update masks and
`$$calc` accept expressions over tags and field names:

```
#all - built-in pseudo-tag: every field of the collection
#none, #required
! - inversion
- - all items on the left, except those on the right
+,  - union of items
()  - grouping
```

Example: `doc.fields.$$calc('#all-#system-#computed')`.

## Runtime helpers attached by `config.link`

| Helper | Purpose |
| --------------- | ------------------------------------------------------------ |
| `$$new(options)` | Fresh document object initialized with type defaults |
| `$$fix(value, options)` | Universal worker: creates/updates a field container field by field (options: `update`, `mask`, `newVal`, `edit`, ...) |
| `$$get(value, mask, options)` | Field-masked read projection |
| `$$set(value, update, options)` | Merge `update` into a field container |
| `$$update(value, updateMask, options)` | Applies user-selected changes considering the user's access mask |
| `$$wasTouched(value)` | Was the value edited (uses `$$touched` bookkeeping) |
| `$$access(user?)` | Per-user `{view, update, required, actions}` permission masks |
| `$$docAccess(doc, user)` | `$$access` additionally restricted by the rights system |
| `$$validate(result, fields, options)` | Full strict validation (types, ranges, regexp, enum, refers, custom validators) |
| `$$editValidate(fields, options)` | Edit-session-friendly validation of touched fields |

## Utility modules

- **`BitArray`** — the backbone of field masks; supports tag expressions in `set`,
  `invert`, `or/and/add/subtract`, `isEmpty`, `lock()` (copy-on-write after locking).
- **`sortedMap`** — ordered name→item map with `$$list` and per-item `$$index`;
  name validation via `checkDocumentName` / `checkUDTypeName` / `checkAPIName` / `checkTagName`.
- **`flatMap`** — sortedMap with chained subitems: builds `$$flat` (all items addressed by
  dotted `fullname`) and per-item `$$mask` BitArrays.
- **`compareStructures`** — deep structural diff reported as `Result` messages
  (`missing`, `extra`, `diffType`, `diffValue`); powers the `sameStructure` test matcher.

## Requirements & dependencies

- Runtime: a `Promise` global must be available (the specs run with Bluebird as the global).
- Dependencies: `lodash`; `moment` is used by date/time validation (currently listed as a
  devDependency — include it in your project).
- Source is CoffeeScript 2; compiled output lives in `lib/`.

## Development

```
npm install
npm run build          # compile & test: --dev/--coverage options available, watch mode support
```

The build pipeline compiles `src/` into ES-next with `coffee --transpile` (Babel), compiles
`spec/` and `samples/`, runs the jasmine suite over the result, copies `temp/src/` → `lib/`,
and generates docco documentation from `spec/**.litcoffee` into `docco/`.

> Note: `scripts/build.js` currently imports its task runner from a path outside this repo
> (the author's monorepo), so it needs adaptation before use in a standalone environment.

### Tests

~40 jasmine suites live in `spec/` as **literate CoffeeScript** (`*.litcoffee`): prose is
documentation, indented code is executable tests.

Custom matchers: `resultContains` (expected `Result` messages present) and
`sameStructure` (deep comparison via `compareStructures`). Since jasmine resets `require.cache`,
the library avoids `instanceof`-based checks and uses duck typing (`isResult`).

Quick local run (with CoffeeScript registration):

```json
{
  "spec_dir": "spec",
  "spec_files": ["*.litcoffee", "_helpers/*.litcoffee"],
  "requires": ["coffeescript/register"]
}
```

```
npx jasmine --config=jasmine.json
```

## Notes

- `package.json` points `main` to `./lib/dscommon.js`, while the compiled entry point here is
  `lib/index.js` — adjust `main` when adopting this repo standalone.
- `Reporter` renders message text via `i18n.format` and prints via an overridable `_print`.

## License

ISC © Alexey Zorkaltsev (alexey@zorkaltsev.com)
