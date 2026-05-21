# Koka Respo Plan

## Goal

The target is not "React compatibility" as branding. The target is a clearer React-style component model:

- business code should describe components and local interactions, not manual scope plumbing
- app structure should look like one component tree, not several hand-wired state islands
- global model should keep domain data; component runtime state should move toward framework-owned storage
- app-level events should use the same component listener path as feature-level events whenever practical

## Directory View

### `koka/respo/*`

Framework core. This directory should keep moving toward the real component runtime boundary.

- `core.kk`: vnode constructors and small DOM-facing helpers
- `state.kk`: hook scopes, local state cells, effect scheduling, listener registry, component runners
- `renderer.kk`: render, diff, and patch planning

Current status:

- local hook APIs and named local listeners are in place
- `component_in(...)`, `on_local_*`, and named state helpers already hide most slot details from business code
- listener registries can detect duplicate ids and semantic drift

Main problems still open here:

- root app rendering is still thinner than child component rendering
- `use_effect(...)` still leaks host-specific `root_id` and has no cleanup contract
- Enter is still modeled through click-oriented storage/dispatch internals
- local state still lives in feature-owned trees stored on the app model

### `koka/demo/*`

Feature and shell layer. This directory should become a thin composition layer around the framework runtime.

- `model.kk`: shared domain data and cross-feature effect declarations only
- `layout.kk`, `view.kk`, `routebar.kk`: app shell and top-level composition
- `todo/*`: todo feature
- `lab/*`: workflow/search/bridge feature
- `dialogs.kk`, `effectspanel.kk`: overlay/effect demos

Current status:

- todo item actions are already mostly local-listener driven
- dialog open/close/submit flows are already local-listener driven
- lab incident card interactions use component-local listeners and local state helpers

Main problems still open here:

- app shell still manually orchestrates several stateful slices and then merges handlers/effects
- route bar still needs to follow the same component-local event model as feature views
- `demo/model.kk` still stores feature local trees, so feature runtime state still leaks into app data shape

### `koka/boilerplate/*` and `koka/runtime/*`

Host boundary only.

- browser boot
- delegated DOM events
- hash sync
- DOM patch application
- confirm/time/bridge host wiring

Rule:

- keep this thin
- do not move feature behavior here
- only host-specific mechanics belong here

### `koka/library/*`

Shared domain helpers and effect-oriented utilities.

- route, dialog, maybe, search, bridge

Rule:

- keep reusable data contracts and helper logic here
- do not let this directory become a second controller layer

### `koka/demo/tests/*`

Regression surface for the React-style component runtime.

Required coverage direction:

- vnode payloads should match registered local listeners
- component-local state should survive rerender and reset only on real identity changes
- shell-level interactions should use the same registry path model as feature-level interactions
- runtime warnings and event dispatch edge cases should stay deterministic

## Task Breakdown

### Phase 1: Make the app shell behave like a component tree

Target:

- app root gets an explicit component/runtime entry
- route bar and other shell interactions stop using raw global click payloads when they can use local listeners
- tests assert shell listener paths the same way they already assert todo/dialog paths

Tasks:

- add a root app component runner in `koka/demo/view.kk`
- move `koka/demo/routebar.kk` to local component listeners
- route app-level harness/tests through the same runtime entry

### Phase 2: Reduce manual orchestration in the shell

Target:

- `layout.kk` should stop looking like a hand-merged collection of islands

Tasks:

- factor repeated child runner merge patterns behind framework helpers
- decide whether stateful child composition belongs in `respo/state.kk` or a thin app-shell helper layer
- keep effect/registry merging explicit only where ownership boundaries are real

### Phase 3: Move local runtime state out of domain model shape

Target:

- `demo/model.kk` should carry domain state, not per-feature runtime storage details

Tasks:

- identify one root-owned local state tree shape in framework/runtime code
- migrate `todo_local_tree`, `lab.local_tree`, and `dialog_local_tree` toward framework-owned storage
- keep feature code reading local state through component helpers, not tree fields

### Phase 4: Tighten hook and effect semantics

Target:

- make hook APIs look more like component runtime primitives and less like host plumbing

Tasks:

- redesign `use_effect(...)` so host-specific root lookup is not the public component contract
- add cleanup support if Koka effect handling can express it cleanly enough
- normalize Enter handling so it is not stored and dispatched through click-oriented paths

### Phase 5: Trim global fallback routing

Target:

- global reducer/controller fallback should be the exception, not the normal feature path

Tasks:

- keep route/hash and true app-level fallbacks global only where necessary
- continue shrinking raw payload decoding in `demo/todo/events.kk` and `demo/lab/events.kk`
- prefer component-local registry dispatch over string decoding when the interaction originates inside a rendered component

## Current Working Set

The next implementation slice is the first Phase 3 migration.

- keep the shared app-owned runtime tree small at first
- migrate dialog overlay local runtime state before moving todo/lab
- validate that the shared tree is keyed by component paths rather than feature-specific storage slots

## Non-Goals

- SSR or hydration
- a 1:1 port of React internals
- hook parity for its own sake
- premature DOM optimization before the component/runtime ownership model is cleaner
