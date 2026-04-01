import { apiInitializer } from "discourse/lib/api";

const COMPONENT_ID = "iframe-auto-height";
const READY_ATTR = "data-auto-height-ready";
const MIN_HEIGHT = 200;
const MAX_HEIGHT = 12000;

// Change this to the iframe origin(s) you control.
const MANAGED_ORIGINS = ["https://noobish.me"];

function getIframeOrigin(iframe) {
  try {
    return new URL(iframe.src, window.location.href).origin;
  } catch {
    return null;
  }
}

function isManagedIframe(iframe) {
  if (!(iframe instanceof HTMLIFrameElement)) return false;

  const origin = getIframeOrigin(iframe);
  return !!origin && MANAGED_ORIGINS.includes(origin);
}

function ensureIframeId(iframe) {
  if (!iframe.dataset.iframeAutoHeightId) {
    const srcId = (() => {
      try {
        return new URL(iframe.src, window.location.href).searchParams.get("iframeId");
      } catch {
        return null;
      }
    })();

    iframe.dataset.iframeAutoHeightId =
      srcId ||
      iframe.getAttribute("id") ||
      `iframe-${Math.random().toString(36).slice(2, 10)}`;
  }

  if (!iframe.id) {
    iframe.id = iframe.dataset.iframeAutoHeightId;
  }

  return iframe.dataset.iframeAutoHeightId;
}

function setIframeHeight(iframe, height) {
  const nextHeight = Math.max(MIN_HEIGHT, Math.min(MAX_HEIGHT, height));
  iframe.style.height = `${nextHeight}px`;
  iframe.style.width = "100%";
  iframe.style.border = "0";
  iframe.setAttribute("scrolling", "no");
}

function sendParentReadyMessage(iframe) {
  if (!iframe.contentWindow) return;

  const targetOrigin = getIframeOrigin(iframe);
  if (!targetOrigin) return;

  iframe.contentWindow.postMessage(
    {
      type: "discourse-iframe-parent-ready",
      iframeId: ensureIframeId(iframe),
    },
    targetOrigin
  );
}

function prepareIframe(iframe) {
  if (!isManagedIframe(iframe)) return;
  if (iframe.getAttribute(READY_ATTR) === "true") return;

  ensureIframeId(iframe);

  if (!iframe.style.height) {
    iframe.style.height = iframe.getAttribute("height")
      ? `${parseInt(iframe.getAttribute("height"), 10) || 600}px`
      : "600px";
  }

  iframe.style.width = "100%";
  iframe.style.border = "0";
  iframe.setAttribute("loading", iframe.getAttribute("loading") || "lazy");
  iframe.setAttribute("scrolling", "no");
  iframe.setAttribute(READY_ATTR, "true");

  iframe.addEventListener("load", () => {
    sendParentReadyMessage(iframe);
  });

  sendParentReadyMessage(iframe);
}

export default apiInitializer("0.11.1", (api) => {
  api.decorateCookedElement(
    (cooked) => {
      cooked.querySelectorAll("iframe").forEach((iframe) => {
        prepareIframe(iframe);
      });
    },
    { id: COMPONENT_ID, onlyStream: true }
  );

  if (window.__iframeAutoHeightMessageListenerInstalled) {
    return;
  }

  window.__iframeAutoHeightMessageListenerInstalled = true;

  window.addEventListener("message", (event) => {
    const data = event.data;

    if (!data || typeof data !== "object") return;
    if (data.type !== "discourse-iframe-height") return;
    if (!data.iframeId) return;
    if (typeof data.height !== "number") return;
    if (!MANAGED_ORIGINS.includes(event.origin)) return;

    const iframe = document.querySelector(
      `iframe[data-iframe-auto-height-id="${CSS.escape(data.iframeId)}"]`
    );

    if (!iframe) return;
    if (!isManagedIframe(iframe)) return;

    setIframeHeight(iframe, Math.ceil(data.height));
  });
});
