# Koka Respo Plan

## Current Status

The exploration phase is complete. This repo now has a working `jsweb`-target Koka UI runtime with:

- VDOM render, diff, and patch in Koka
- thin browser handlers in `koka/app.kk` and `koka/runtime/*`
- slot-based generic local UI state in `koka/respo/state.kk`
- a unified listener registration effect with semantic listener ids
- framework-side warnings for duplicate listener registration and semantic drift
- higher-level node helpers in `koka/respo/core.kk` to reduce business-component boilerplate
- split feature modules for todo and workflow lab
- deterministic in-process tests and a production build pipeline
- CI/deploy support for the static site build

## What Is Done

### Runtime and host

- `yarn dev`, `yarn build`, and `yarn test:koka` are the normal entry points
- browser integration is intentionally thin: DOM patching, event delegation, route hash, confirm, timestamps, and runtime warning logs
- build output is deployed as a static app with relative asset paths

### State and listener model

- global application data remains in `demo/model.kk`
- seeded boot data and mock lab responses live in `demo/seed.kk`
- component-local state uses generic `use_state` / `use_state_pair` with codecs
- hooks use stable component scope plus index semantics
- listeners use semantic identity instead of hook index semantics
- the view layer depends on one generic listener effect: `register_listener<...>`
- named local listeners are collected into an event registry and routed through delegated DOM events
- registry warnings cover duplicate listener ids and semantic drift across render/merge boundaries

### Framework helpers

- `koka/respo/core.kk` now provides higher-level helpers such as `node_class`, `text_class`, `button_class`, and `text_input`
- business components no longer need to repeat low-level `props([class_attr(...)], ...)` patterns everywhere
- the framework is intentionally a bit thicker so feature components stay smaller and easier to read

### Feature structure

- todo is split into `demo/todo/state.kk`, `view.kk`, and `events.kk`
- workflow lab is split into `demo/lab/state.kk`, `view.kk`, `events.kk`, and `workflow.kk`
- `demo/todopanel.kk` and `demo/labpanel.kk` are thin facades so outer call sites stay stable
- `demo/model.kk` is closer to a domain shell plus shared selectors and effect declarations, instead of also owning feature reducers
- feature views now use the framework helpers rather than defining repeated local view helpers per module

### Tests

- tests are split into `demo/tests/support.kk`, `basics.kk`, `statecases.kk`, `todocases.kk`, and `labcases.kk`
- the test suite validates render snapshots, local state, effect handling, workflow behavior, and listener registry guard behavior
- listener collisions and semantic drift now have explicit regression coverage

## Current Module Map

- `koka/app.kk`: browser boot, handler installation, and runtime warning logging
- `koka/demo/model.kk`: shared types, selectors, routes, and effect declarations
- `koka/demo/seed.kk`: initial model and deterministic lab mocks
- `koka/demo/todo/*`: todo local state, events, and rendering
- `koka/demo/lab/*`: workflow lab local state, events, workflow actions, and rendering
- `koka/demo/tests/*`: support helpers and focused case files
- `koka/respo/core.kk`: VDOM core plus higher-level view constructors
- `koka/respo/state.kk`: local state runtime, hook scope management, listener registration, and registry guards
- `koka/respo/renderer.kk`: VDOM rendering, diff, and patch planning

## Next Cuts

### Near term

- add auto-scoped listener helpers so business components no longer have to thread `item_scope` / `panel_scope` manually
- unify the repeated `run_local_state(...) + run_event_registry(...)` orchestration behind a framework helper
- decide whether listener warnings should stay as logs only or optionally fail in dev/test mode
- keep shrinking `demo/model.kk` so it stays focused on shared domain data and cross-feature selectors only

### Optional follow-up

- normalize the internal listener registry naming so Enter is no longer modeled through the click-oriented storage path
- add another demo feature that exercises the same slot-state and effect-handler runtime without copying todo/lab structure
- keep moving reusable view patterns from `demo/*` into `respo/core.kk` only when they clearly reduce feature-code cost

## Non-Goals

- SSR or hydration
- React hook parity as a goal by itself
- a 1:1 reimplementation of React’s event internals
- premature DOM optimization beyond what the current diff/patch runtime already supports
