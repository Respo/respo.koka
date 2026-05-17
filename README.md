# Koka Algebraic Effects in a React-like UI

This project is a focused experiment: build a React-style UI architecture where component description, state transitions, and diff/patch all stay in Koka, while JavaScript is limited to DOM and browser/system boundaries.

The result is not “React rewritten in Koka”. It is closer to a Respo-style runtime with React-like ergonomics:

- view functions return virtual DOM nodes
- reducers produce the next immutable model
- algebraic effects model side effects explicitly
- effect handlers swap runtime behavior in browser and tests
- JavaScript FFI only touches DOM events, DOM patching, browser hash, clocks, and similar host capabilities

## Why this repo exists

React Hooks made “stateful UI as plain functions” feel normal. Koka pushes that idea further by making side effects part of the type system and by letting us handle those effects explicitly.

That gives this project three practical goals:

1. Keep rendering and state logic in Koka.
2. Keep host integration thin and replaceable.
3. Make async flows and tests use the same effect surface instead of duplicating logic.

## How the architecture maps to React

Here is the rough correspondence used in this repo.

| React idea                  | This repo in Koka                                                         |
| --------------------------- | ------------------------------------------------------------------------- |
| function component          | `demo/*panel.kk` functions that return `vnode`                            |
| application state           | `demo/model.kk` immutable `model` plus seeded boot data in `demo/seed.kk` |
| `setState` / reducer update | reducer functions returning a fresh `model`                               |
| context                     | `val` effects like `current_filter`, `current_operator`                   |
| async service layer         | effect operations like `wait_ms`, `fetch_lab_snapshot`, `post_lab_reply`  |
| controlled inputs           | reducer + input listeners + host sync / `value` attrs                     |
| local component state       | path-keyed local state tree in `respo/state.kk`                           |
| test doubles                | handlers in `demo/tests/support.kk` and focused case modules              |

The important difference is that React usually hides effects behind conventions, while Koka makes them explicit in function types.

## Project layout

- `koka/respo/core.kk`: VDOM data structures and helpers.
- `koka/respo/renderer.kk`: render, diff, and patch planning.
- `koka/respo/state.kk`: generic slot-based local state runtime with codec-backed `use_state` / `set_state`.
- `koka/demo/model.kk`: domain types, shared selectors, route normalization, and effect surface declarations.
- `koka/demo/seed.kk`: seeded initial model plus deterministic lab snapshot / reply mocks.
- `koka/demo/todo/state.kk`, `view.kk`, `events.kk`: Todo local state, rendering, and routed interactions.
- `koka/demo/lab/state.kk`, `view.kk`, `events.kk`, `workflow.kk`: lab local state, rendering, routed interactions, and staged workflow actions.
- `koka/demo/todopanel.kk` and `koka/demo/labpanel.kk`: thin public facades over the split feature modules.
- `koka/demo/tests/support.kk` and `koka/demo/tests/*.kk`: effect-driven tests split by concern.
- `koka/app.kk`: browser orchestration and handler installation.
- `koka/runtime/inline/dom.js`: DOM/system bridge only.

## The core pattern

Most of the app follows one simple split:

1. Define a pure-ish reducer that returns a new model but declares the effects it may need.
2. Install concrete handlers at the application boundary.
3. Reuse the same reducer under different handlers in tests.

In other words, the app logic asks for capabilities like “confirm”, “wait”, or “fetch a snapshot”, but never hardcodes how those are implemented.

## Case study 1: destructive UI flows without hard-wired browser calls

In React, a delete button often closes over `window.confirm()` directly, or delegates to a service helper. In this repo, destructive flows are represented as effects:

```koka
pub effect fun confirm_action(message : string) : bool
pub effect fun audit(message : string) : ()
```

The reducer can say exactly what it needs:

```koka
pub fun handle_remove(item : model, payload : string) : <confirm_action,audit,div> model
```

That means:

- the reducer may ask for confirmation
- the reducer may emit an audit record
- the reducer may use ordinary recursive `div` code
- it does not know or care whether the handler is a browser dialog, a test stub, or something else later

In the browser boundary, `app.kk` installs concrete behavior:

```koka
with fun confirm_action(message) browser_confirm(message)
with fun audit(message) browser_log(message)
```

In tests, the same reducer runs under different handlers:

- always confirm
- always decline
- capture audit logs into a list

This is the first major advantage over ad-hoc React side effects: the effect surface is typed, composable, and testable.

## Case study 2: ambient context without prop drilling

The todo list filter is implemented as a value effect:

```koka
pub effect val current_filter : string
```

`visible_tasks` depends on that filter implicitly:

```koka
pub fun visible_tasks(tasks : list<task>) : <current_filter,div> list<task>
```

And `tasks_for` binds it at the edge:

```koka
pub fun tasks_for(filter_name : string, tasks : list<task>) : <div> list<task>
  with val current_filter = filter_name
  visible_tasks(tasks)
```

This plays a role similar to React Context, but with a smaller semantic surface:

- the dependency is explicit in the type
- the binding is lexical and local
- tests can bind different values without a provider tree

## Case study 3: local component state without moving everything into the main model

One risk in reducer-driven UIs is shoving every tiny UI concern into the global model. That makes “editing”, “expanded”, “draft in an input”, and “temporary focus-like state” feel heavier than they should.

This repo uses a small path-keyed state tree in `koka/respo/state.kk`:

```koka
pub struct state_entry(path : string, kind : string, text_value : string, flag_value : bool)
```

The current API centers on generic local slots:

- `slot(...)` and `named_slot(...)`
- `use_state(...)` and `set_state(...)`
- codec values such as `text_state_codec` and `flag_state_codec`
- `run_local_state(...)` for handler-backed local commits
- `read_local_state(...)` for render-time reads from a concrete tree

### Todo item editing

Each todo item now has local edit state:

- `todo/tasks/<id>/editing`
- `todo/tasks/<id>/draft`

The todo feature is now split across dedicated modules:

- `demo/todo/state.kk` owns slot identities and local commit helpers
- `demo/todo/view.kk` renders item editing state directly through `use_state`
- `demo/todo/events.kk` routes click and input actions into those local commits

This is deliberately React-like in user experience:

1. click `Edit`
2. open local draft state for one item
3. change the input many times
4. only on `Save` commit the title into the actual task list

The difference is where the behavior lives:

- React would usually keep this in `useState`
- here it is still reducer-driven, but stored in a dedicated local state tree rather than polluting the main domain record

That makes it easier to inspect, clear, and test.

## Case study 4: async workflow demo with time and mock server data

The workflow lab is the clearest demonstration of why algebraic effects are useful for UI code. The effect surface includes:

```koka
pub effect fun wait_ms(delay : int) : ()
pub effect fun fetch_lab_snapshot() : lab_snapshot
pub effect fun post_lab_reply(incident_id : int, message : string) : string
pub effect fun now_label() : string
pub effect val current_operator : string
```

This models a realistic front-end workflow:

- staged loading
- server reads
- server writes
- timestamps
- operator identity
- audit side effects

The workflow actions stay high-level, but they no longer live in the main model file:

- `load_snapshot`
- `perform_sync`
- `send_reply`

Those actions now live in `koka/demo/lab/workflow.kk`, while `demo/lab/events.kk` decides when to call them and `demo/lab/state.kk` handles per-card local draft / expanded state.

Each function reads like business logic instead of callback plumbing.

For example, `send_reply` can express:

1. validate local draft
2. emit audit
3. wait for staged network time
4. call the reply operation
5. stamp the result with time and operator
6. update the model and clear local draft state

That is the same kind of workflow many React apps implement with a mixture of:

- hook state
- async helper functions
- service modules
- test mocks
- global stores

Here the logic remains inside one typed Koka reducer.

## Case study 5: tests use the same effect surface as production

This is where the design pays off hardest.

The split test modules under `koka/demo/tests/` do not need a fake browser or a fake HTTP client framework. They just install different handlers.

For example, timer-heavy logic is tested by handling `wait_ms` and recording the delays immediately:

```koka
fun capture_waits(action : () -> <wait_ms|e> string) : e (string, list<int>)
  var waits := Nil
  with return(result) (result, waits)
  with fun wait_ms(delay) waits := Cons(delay, waits)
  action()
```

The workflow tests do the same for multiple effects at once:

- collect waits
- return a deterministic timestamp
- return deterministic mock server responses
- capture audit output
- provide a fake operator identity

That means the production reducer and the test reducer are literally the same function body.

In React projects, teams often say “test behavior, not implementation”. Algebraic effects make that easier because the behavior boundary is already explicit and typed.

## Why this works well for a React-style system

The React programming model is attractive because it keeps UI as functions of state. The pain usually appears at the boundaries:

- async flows get smeared across hooks and helpers
- context can become implicit and hard to audit
- browser-only APIs leak into components
- testing needs framework-specific mocking layers

Koka’s algebraic effects improve exactly those boundary problems:

- effectful dependencies are part of the function type
- handler installation is centralized
- the same reducer can run in browser and tests
- local state can still be modeled without losing reducer discipline

## What JavaScript still does here

This project is not trying to eliminate JavaScript entirely. It uses JS FFI only where the browser is the real owner:

- mount HTML into the DOM
- patch changed DOM nodes
- listen to delegated input/click/keydown events
- read and write the hash route
- call browser confirm
- print logs
- read wall-clock time labels

Everything above that line stays in Koka.

## Running the project

```bash
yarn dev
yarn build
yarn test:koka
```

Useful reading order in the codebase:

1. `koka/app.kk`
2. `koka/demo/seed.kk`
3. `koka/demo/model.kk`
4. `koka/demo/todo/state.kk`, `view.kk`, `events.kk`
5. `koka/demo/lab/state.kk`, `view.kk`, `events.kk`, `workflow.kk`
6. `koka/demo/tests/support.kk` and `koka/demo/tests/*.kk`
7. `koka/respo/state.kk`

## Takeaway

The main point of this repo is not that Koka can render a todo list.

The point is that Algebraic Effects can provide a practical React-like UI architecture where:

- rendering stays functional
- side effects stay explicit
- local state stays lightweight
- async workflows stay readable
- tests stay close to the production execution model

If you already like the React mental model but want stronger control over effect boundaries, this repo shows one concrete direction for doing that.
