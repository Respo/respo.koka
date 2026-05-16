# Koka Respo Exploration Plan

## Goal

Build a small frontend framework in Koka that follows a React-like mental model:

- immutable state and explicit updates
- Virtual DOM diffing and patching
- component-local state by path
- effect handlers for business flows rather than DOM mutation scheduling

The first milestone is a working Todolist rendered from a Koka program compiled with `--target=wasmweb`, loaded by a Vite page.

## Feasibility Notes

### What is already verified locally

- `koka` is installed and available at `/usr/local/bin/koka`
- Koka `3.2.3` supports `jsweb` and `wasmweb` targets
- Koka stdlib already uses `extern import js file "..."` for backend interop

### Why this is a reasonable direction

React Hooks were influenced by algebraic effects at the model level, but React itself is not an algebraic-effects runtime. Koka lets us push that idea further:

- use effect handlers to model ambient services and business capabilities
- keep rendering as a pure tree transform from state to VDOM
- isolate imperative DOM work behind a renderer boundary

That means we do not need to re-implement React. We can build a smaller system whose design is:

- React-like in component shape and unidirectional updates
- Respo-like in immutable tree state and cursor-based local state
- Koka-like in typed effects for workflows such as confirmation, filtering, drafts, persistence stubs, or undo

## Source Inspirations

### From Respo / Respo.rs / respo.mbt

- immutable store and render skipping based on equality
- local state stored by path or cursor
- effects attached to component lifecycle are limited and explicit
- Todolist is a good first benchmark because it exercises local state, list diffing, and keyed updates

### From Koka samples

- `handlers/basic.kk`: state, exceptions, iteration, resumption
- `handlers/ambient.kk`: ambient values and dynamically scoped capabilities
- `handlers/yield.kk`: producer-style effects that can be used for UI or event streams

## Architecture Decision

### Runtime split

- Koka owns data types, update logic, Virtual DOM, diffing, and effectful business flows
- TypeScript owns Vite dev server, CSS, and the tiny browser bootstrap that loads the wasm output
- JavaScript FFI files are allowed only at the renderer boundary and for browser APIs

### Initial module plan

- `koka/app.kk`: app entry and bootstrapping
- `koka/vdom/node.kk`: VDOM node definitions
- `koka/vdom/diff.kk`: tree diff
- `koka/vdom/patch.kk`: patch representation and patch execution bridge
- `koka/runtime/dom.kk`: browser FFI bindings
- `koka/runtime/state.kk`: store, cursors, local state helpers
- `koka/features/todolist/*.kk`: demo application
- `koka/features/effects/*.kk`: business cases centered on algebraic effects

### UI model

- `view(model) -> vnode`
- `update(action, model) -> model`
- `dispatch(action)` schedules re-render
- list children use stable keys
- local state is addressed by a path, similar to Respo states tree

## Planned Milestones

### Milestone 1: host app and build pipeline

- scaffold a Vite host
- add a build script that compiles Koka to `wasmweb`
- load the emitted module from the page

### Milestone 2: minimal renderer

- define a typed VDOM
- render initial tree to DOM
- add keyed child diffing for Todolist-level updates

### Milestone 3: Todolist

- add item
- toggle done
- remove item
- filter done items
- draft text local state

### Milestone 4: algebraic effects features

- confirmation effect before destructive delete
- ambient filter policy effect for alternate views
- undo or transient notification effect
- optional persistence capability effect with an in-memory handler first

## Non-Goals For The First Iteration

- SSR
- hydration
- general-purpose hook parity with React
- aggressive renderer optimization beyond keyed diffing

## Risk Notes

- Koka `wasmweb` browser interop may require small JS adapters
- the first renderer should prefer correctness over minimal DOM mutations
- keyed diffing should be limited to what the Todolist actually needs first

## Immediate Build Order

1. Initialize Vite in the empty folder.
2. Add Koka source layout and build scripts.
3. Prove `hello from wasmweb` renders into the page.
4. Replace direct DOM demo with Koka-managed VDOM rendering.
5. Build Todolist.
6. Add algebraic-effects-driven features.
