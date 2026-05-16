import "./style.css";
import {
  boot,
  dispatchClick,
  dispatchInput,
  dispatchRoute,
} from "./generated/koka-entry";

declare global {
  interface Window {
    __kokaDispatchClick?: (payload: string) => void;
    __kokaDispatchInput?: (channel: string, value: string) => void;
    __kokaDispatchRoute?: (routeName: string) => void;
  }
}

const root = document.querySelector<HTMLDivElement>("#app");

if (root === null) {
  throw new Error("Missing #app root element.");
}

window.__kokaDispatchClick = dispatchClick;
window.__kokaDispatchInput = dispatchInput;
window.__kokaDispatchRoute = dispatchRoute;

boot("app");
