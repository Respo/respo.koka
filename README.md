# Koka Algebraic Effects in a React-like UI

> This repository is an AI-generated and AI-assisted experimental project.
>
> Treat it as a research prototype, not as a recommended framework or a production-ready starter.
>
> The suggested way to use it is to fork it and continue the exploration in your own direction.
> It is not recommended to adopt it directly as-is.

This repo explores one specific question:

Can Algebraic Effects be used as a first-class architectural tool in a React-like frontend system?

The answer here is not “React rewritten in Koka”. The result is closer to a small Respo-style runtime with a React-like mental model:

- components are plain functions returning virtual DOM
- state updates return a fresh immutable model
- local UI state is still available where it helps
- browser and service capabilities are expressed as effects
- browser and tests install different handlers over the same UI logic

The main value of the repo is this exploration of the boundary between frontend frameworks and Algebraic Effects.

## What this repo is actually exploring

Most frontend frameworks are already good at rendering trees from state. The harder parts are usually at the edges:

- async workflows get spread across hooks, services, and callback glue
- browser APIs leak into components
- Context grows implicit and hard to audit
- tests need framework-specific mocking layers

This repo explores a different split:

1. Keep view description, state transitions, and diff/patch planning in Koka.
2. Keep JavaScript limited to DOM and browser boundaries.
3. Use Algebraic Effects to model the capabilities the UI logic needs.
4. Install those capabilities differently in browser and tests.

That makes the interesting question not “can Koka render a todo app?”, but “what changes when frontend capabilities become typed effects instead of conventions?”

## How the component model maps to React

The overall shape is intentionally familiar.

| React idea          | This repo in Koka                                                       |
| ------------------- | ----------------------------------------------------------------------- |
| function component  | `demo/*panel.kk` and `demo/*/view.kk` functions returning `vnode`       |
| reducer update      | functions returning a fresh `model`                                     |
| local hook state    | slot-based local state in `respo/state.kk`                              |
| Context             | `val` effects such as `current_filter` and `current_operator`           |
| async service layer | `fun` effects such as `wait_ms`, `fetch_lab_snapshot`, `post_lab_reply` |
| test doubles        | alternate effect handlers in test modules                               |

The key difference is that React typically leaves effect boundaries as framework convention, while Koka makes them part of the function type.

## What component code looks like

The component style is meant to stay close to the “plain function UI” feel that makes React ergonomic.

For example, the todo panel renders as a function of the current model while still using local state and typed event hooks:

```koka
pub fun render_todo_panel(item : model)
  : <use_state,use_effect,on_click<model,browser_event_effect>,on_input<model>,on_enter<model,browser_event_effect>,div> vnode
  panel("Todo", model_notice(item), "todo", "todo-panel", [
    el("input", "draft",
      [class_attr("input"), text_attr("value", model_draft(item))],
      [
        on_input(draft_input_slot(), fn(value, owner) set_draft(owner, value)),
        on_enter(todo_enter_slot("add-task"), fn(owner) route_todo("add-task", owner)),
      ],
      "", Nil),
    el("button", "add-task",
      [class_attr("button button-primary")],
      [on_click(todo_click_slot("add-task"), fn(owner) route_todo("add-task", owner))],
      "Add", Nil),
  ])
```

What is notable here is not the syntax itself. It is the division of responsibility:

- the view stays a plain function
- local UI state still exists through `use_state_pair(...)`
- event handlers close over typed state transitions
- those handlers can require capabilities without directly touching browser APIs

That is the point where Algebraic Effects start to matter for frontend architecture.

## Where Algebraic Effects change the design

### 1. Side effects become explicit UI capabilities

Instead of a reducer or event path closing over `window.confirm()` or some service singleton, the code declares what it needs:

```koka
pub effect fun confirm_action(message : string) : bool
pub effect fun audit(message : string) : ()
```

Then a reducer can say:

```koka
pub fun handle_remove(item : model, payload : string) : <confirm_action,audit,div> model
```

That means the UI logic depends on confirmation and audit, but does not decide how those capabilities are implemented.

In the browser boundary, `app.kk` installs one behavior. In tests, the same code runs under different handlers.

This is one of the clearest places where Algebraic Effects are a better fit than common React patterns: the dependency is visible in the type, not hidden in a closure or convention.

### 2. Async workflows stay in one reducer-shaped flow

The workflow demo uses effects like:

```koka
pub effect fun wait_ms(delay : int) : ()
pub effect fun fetch_lab_snapshot() : lab_snapshot
pub effect fun post_lab_reply(incident_id : int, message : string) : string
pub effect fun now_label() : string
pub effect val current_operator : string
```

This lets a workflow action express a frontend flow directly:

1. validate local draft state
2. emit audit
3. wait for staged time
4. fetch or post data
5. stamp with time and operator
6. return the next immutable model

In a React codebase, this kind of logic often gets split across hook state, service helpers, async callbacks, and mock-specific test code.

Here the experiment is: keep it in one typed reducer-like path, and swap implementations by installing handlers.

That does not magically make async UI trivial. It does make the capability boundary much sharper.

### 3. Ambient values become explicit without provider ceremony

The repo also uses `val` effects for contextual values such as filters and operator identity.

```koka
pub effect val current_filter : string
```

This plays a role similar to React Context, but with different tradeoffs:

- the dependency is explicit in the function type
- the binding is lexical
- tests can override it with a tiny local handler
- there is less provider-tree ceremony

This is another useful direction for frontend exploration: context-like behavior with smaller framework surface area.

### 4. Tests use the same capability surface as production

The strongest result in this repo is not visual. It is architectural.

The production code and the tests use the same effect surface.

For example, timer-heavy logic can be tested by handling `wait_ms` immediately and collecting delays, while workflow tests can install fake timestamps, fake operator identity, fake server responses, and audit collectors.

That means the business path is not rewritten for tests. Only the handlers change.

This is one place where Algebraic Effects fit frontend work unusually well: UI logic is full of environment-dependent behavior, and handlers give that environment a clean, typed boundary.

## Why this is interesting for frontend frameworks

This repo is an exploration of how Algebraic Effects and frontend frameworks can complement each other.

The React lesson worth keeping is: UI should mostly feel like functions of state.

The part worth rethinking is: where should side effects, async capabilities, ambient values, and test doubles live?

This repo explores one answer:

- rendering stays functional
- effects become typed capabilities
- handlers become the integration boundary
- browser and tests differ by handler installation, not by rewriting app logic

That combination is the real subject of the experiment.

## What JavaScript still does

JavaScript is still used, but only at the host boundary:

- delegated DOM events
- DOM patching and mounting
- browser hash reads and writes
- browser confirm
- logging
- wall-clock labels and similar host data

Everything above that line is what this repo is trying to keep in Koka.

## If you want to explore this repo

Recommended mindset:

1. Fork it.
2. Treat it as a design sketch, not a final framework.
3. Change the handler surface first, not the renderer details.
4. Evaluate whether the effect boundaries feel clearer than the equivalent React architecture you would normally write.

Useful reading order:

1. `koka/app.kk`
2. `koka/demo/model.kk`
3. `koka/respo/state.kk`
4. `koka/demo/todo/view.kk`
5. `koka/demo/lab/workflow.kk`
6. `koka/demo/tests/support.kk`

Run locally with:

```bash
yarn dev
yarn build
yarn test:koka
```

## Takeaway

This repo is not arguing that frontend teams should stop using React and move to Koka.

It is a narrower claim:

Algebraic Effects appear to be a promising tool for frontend framework design, especially for modeling capabilities that React apps usually express through informal conventions: async workflows, browser integration, contextual values, and test doubles.

If that is the question you care about, this repo is worth forking and pushing further.
