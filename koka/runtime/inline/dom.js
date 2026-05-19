function _root_of(rootId) {
  const root = document.getElementById(rootId);

  if (root == null) {
    throw new Error(`Missing root element: ${rootId}`);
  }

  return root;
}

function _mount_html(rootId, html) {
  _root_of(rootId).innerHTML = html;
}

function _attach_events(rootId) {
  const root = _root_of(rootId);

  if (root.dataset.kokaAttached === "true") {
    return;
  }

  root.dataset.kokaAttached = "true";

  root.addEventListener("click", (event) => {
    const target = event.target;

    if (!(target instanceof Element)) {
      return;
    }

    const clickable = target.closest("[data-k-click]");

    if (clickable instanceof HTMLElement) {
      globalThis.__kokaDispatchClick?.(String(clickable.dataset.kClick ?? ""));
    }
  });

  root.addEventListener("input", (event) => {
    const target = event.target;

    if (
      !(target instanceof HTMLInputElement) &&
      !(target instanceof HTMLTextAreaElement)
    ) {
      return;
    }

    const channel = target.dataset.kInput;

    if (typeof channel === "string") {
      globalThis.__kokaDispatchInput?.(channel, target.value);
    }
  });

  root.addEventListener("keydown", (event) => {
    const target = event.target;

    if (
      !(target instanceof HTMLInputElement) &&
      !(target instanceof HTMLTextAreaElement)
    ) {
      return;
    }

    if (event.key !== "Enter") {
      return;
    }

    const payload = target.dataset.kEnter;

    if (typeof payload === "string") {
      event.preventDefault();
      globalThis.__kokaDispatchClick?.(payload);
    }
  });

  window.addEventListener("hashchange", () => {
    globalThis.__kokaDispatchRoute?.(_browser_hash());
  });
}

function _patch_html(rootId, path, html) {
  const root = _root_of(rootId);

  if (path === "0") {
    root.innerHTML = html;
    return;
  }

  const current = root.querySelector(`[data-kpath="${path}"]`);

  if (current == null) {
    return;
  }

  const template = document.createElement("template");
  template.innerHTML = html.trim();
  const next = template.content.firstElementChild;

  if (next != null) {
    current.replaceWith(next);
  }
}

function _node_at(rootId, path) {
  const root = _root_of(rootId);

  if (path === "0") {
    return root.querySelector('[data-kpath="0"]') ?? root.firstElementChild;
  }

  return root.querySelector(`[data-kpath="${path}"]`);
}

function _patch_attr(rootId, path, attrName, attrValue) {
  const current = _node_at(rootId, path);

  if (!(current instanceof Element)) {
    return;
  }

  current.setAttribute(attrName, attrValue);

  if (
    attrName === "value" &&
    (current instanceof HTMLInputElement ||
      current instanceof HTMLTextAreaElement)
  ) {
    if (current.value !== attrValue) {
      current.value = attrValue;
    }
  }
}

function _clear_attr(rootId, path, attrName) {
  const current = _node_at(rootId, path);

  if (!(current instanceof Element)) {
    return;
  }

  current.removeAttribute(attrName);

  if (
    attrName === "value" &&
    (current instanceof HTMLInputElement ||
      current instanceof HTMLTextAreaElement)
  ) {
    if (current.value !== "") {
      current.value = "";
    }
  }
}

function _sync_input(rootId, fieldName, value) {
  const root = _root_of(rootId);
  const field = root.querySelector(`[data-k-input="${fieldName}"]`);

  if (
    field instanceof HTMLInputElement ||
    field instanceof HTMLTextAreaElement
  ) {
    if (field.value !== value) {
      field.value = value;
    }
  }
}

function _browser_hash() {
  return String(window.location.hash || "").replace(/^#/, "");
}

function _browser_set_hash(routeName) {
  const nextHash = `#${String(routeName || "overview")}`;

  if (window.location.hash !== nextHash) {
    window.location.hash = nextHash;
  }
}

function _browser_focus(rootId, fieldName) {
  const root = _root_of(rootId);
  const field =
    root.querySelector(`[data-k-effect="${fieldName}"]`) ||
    root.querySelector(`[data-k-input="${fieldName}"]`);

  if (
    field instanceof HTMLInputElement ||
    field instanceof HTMLTextAreaElement
  ) {
    field.focus({ preventScroll: true });
  }
}

function _browser_flash_marker(rootId, markerName, className) {
  const root = _root_of(rootId);
  const target = root.querySelector(`[data-k-effect="${markerName}"]`);

  if (!(target instanceof HTMLElement)) {
    return;
  }

  target.classList.remove(className);
  void target.offsetWidth;
  target.classList.add(className);

  window.setTimeout(() => {
    target.classList.remove(className);
  }, 360);
}

function _browser_now_label() {
  return new Date().toLocaleTimeString("en-US", {
    hour12: false,
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
  });
}

function _browser_confirm(message) {
  return window.confirm(message);
}

function _browser_log(message) {
  console.log(message);
}

function _browser_schedule_click(payload, delay) {
  window.setTimeout(() => {
    globalThis.__kokaDispatchClick?.(String(payload));
  }, Number(delay) || 0);
}

function _html_escape(text) {
  return String(text)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}
