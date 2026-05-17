# Koka Respo Plan

## Current Status

The exploration phase is complete. This repo now has a working `jsweb`-target Koka UI runtime with:

- VDOM render, diff, and patch in Koka
- thin browser handlers in `koka/app.kk` and `koka/runtime/*`
- slot-based generic local UI state in `koka/respo/state.kk`
- split feature modules for todo and workflow lab
- deterministic in-process tests and a production build pipeline
- CI/deploy support for the static site build

## What Is Done

### Runtime and host

- `yarn dev`, `yarn build`, and `yarn test:koka` are the normal entry points
- browser integration is intentionally thin: DOM patching, event delegation, route hash, confirm, and timestamps
- build output is deployed as a static app with relative asset paths

### State model

- global application data remains in `demo/model.kk`
- seeded boot data and mock lab responses moved into `demo/seed.kk`
- component-local state is no longer ad hoc text/bool helpers; it now uses generic `use_state` / `set_state` with codecs
- render-time local reads were normalized through `read_local_state(...)`

### Feature structure

- todo is split into `demo/todo/state.kk`, `view.kk`, and `events.kk`
- workflow lab is split into `demo/lab/state.kk`, `view.kk`, `events.kk`, and `workflow.kk`
- `demo/todopanel.kk` and `demo/labpanel.kk` are thin facades so outer call sites stay stable
- `demo/model.kk` is now closer to a domain shell plus shared selectors and effect declarations, instead of also owning feature reducers

### Tests

- tests are split into `demo/tests/support.kk`, `basics.kk`, `statecases.kk`, `todocases.kk`, and `labcases.kk`
- the test suite validates render snapshots, local state, effect handling, and workflow behavior under mocked handlers

## Current Module Map

- `koka/app.kk`: browser boot and handler installation
- `koka/demo/model.kk`: shared types, selectors, routes, and effect declarations
- `koka/demo/seed.kk`: initial model and deterministic lab mocks
- `koka/demo/todo/*`: todo local state, events, and rendering
- `koka/demo/lab/*`: workflow lab local state, events, workflow actions, and rendering
- `koka/demo/tests/*`: support helpers and focused case files
- `koka/respo/*`: VDOM core, renderer, and local state runtime

## Next Cuts

### Near term

- keep shrinking `demo/model.kk` so it stays focused on shared domain data and cross-feature selectors only
- decide whether lab counting/selector helpers should also move into `demo/lab/*`
- add a few more behavior-scoped tests around route fallback and unknown action handling

### Optional follow-up

- split `demo/tests/basics.kk` further if render/effect cases continue growing
- add another demo feature that exercises the same slot-state and effect-handler runtime without copying todo/lab structure

## Non-Goals

- SSR or hydration
- React hook parity as a goal by itself
- premature DOM optimization beyond what the current diff/patch runtime already supports
