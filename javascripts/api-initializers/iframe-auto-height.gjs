import { apiInitializer } from "discourse/lib/api";

const COMPONENT_ID = "iframe-auto-height";
const READY_ATTR = "data-iframe-auto-height-ready";
const MIN_HEIGHT = 200;
const MAX_HEIGHT = 12000;

function getManagedOrigins() {
  const raw = settings.managed_origins;

  if (Array.isArray(raw)) {
    return raw.map((value) => String(value).trim()).filter(Boolean);
  }

  if (typeof raw === "string") {
    return raw
      .split("|")
      .map((value) => value.trim())
      .filter(Boolean);
  }

  if (raw == null) {
    return [];
  }

  return [String(raw).trim()].filter(Boolean);
}

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
  return !!origin && getManagedOrigins().includes(origin);
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
      type: "iframe-parent-ready",
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

  iframe.style.width 
