# **Theme Name**

**Theme Summary**

For more information, please see: **url to meta topic**

```
<script>
(function () {
  const params = new URLSearchParams(window.location.search);
  let resolvedIframeId = params.get("iframeId");
  let parentOrigin = "*";
  let lastHeight = 0;

  function getHeight() {
    const body = document.body;
    const html = document.documentElement;

    return Math.max(
      body ? body.scrollHeight : 0,
      body ? body.offsetHeight : 0,
      html ? html.clientHeight : 0,
      html ? html.scrollHeight : 0,
      html ? html.offsetHeight : 0
    );
  }

  function sendHeight() {
    const height = getHeight();

    if (!resolvedIframeId || !height || height === lastHeight) {
      return;
    }

    lastHeight = height;

    window.parent.postMessage(
      {
        type: "iframe-height",
        iframeId: resolvedIframeId,
        height
      },
      parentOrigin
    );
  }

  function scheduleSend() {
    window.requestAnimationFrame(sendHeight);
    window.setTimeout(sendHeight, 100);
    window.setTimeout(sendHeight, 500);
  }

  window.addEventListener("message", (event) => {
    const data = event.data;

    if (!data || typeof data !== "object") return;
    if (data.type !== "iframe-parent-ready") return;

    parentOrigin = event.origin || "*";

    if (!resolvedIframeId && data.iframeId) {
      resolvedIframeId = data.iframeId;
    }

    scheduleSend();
  });

  window.addEventListener("load", scheduleSend);
  window.addEventListener("resize", scheduleSend);

  if ("ResizeObserver" in window) {
    const ro = new ResizeObserver(() => scheduleSend());
    ro.observe(document.documentElement);
    if (document.body) {
      ro.observe(document.body);
    }
  }

  if ("MutationObserver" in window) {
    const mo = new MutationObserver(() => scheduleSend());
    mo.observe(document.documentElement, {
      childList: true,
      subtree: true,
      attributes: true,
      characterData: true
    });
  }
})();
</script>
```
