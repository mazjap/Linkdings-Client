const $ = id => document.getElementById(id);
const show = id => $( id).classList.remove("hidden");
const hide = id => $( id).classList.add("hidden");

async function sendMessage(message) {
    return browser.runtime.sendMessage(message);
}

async function init() {
    // Check if the app is configured
    const setup = await sendMessage({ type: "checkSetup" }).catch(() => ({ configured: false }));

    if (!setup?.configured) {
        hide("loading");
        show("not-configured");
        return;
    }

    // Get current tab info
    const [tab] = await browser.tabs.query({ active: true, currentWindow: true });

    $("url").value = tab?.url ?? "";
    $("title").value = tab?.title ?? "";

    hide("loading");
    show("main");
    $("url").focus();
}

$("bookmark-form").addEventListener("submit", async (e) => {
    e.preventDefault();

    const url = $("url").value.trim();
    if (!url) return;

    const tagInput = $("tags").value.trim();
    const tagNames = tagInput ? tagInput.split(/\s+/).filter(Boolean) : [];

    const saveBtn = $("save-btn");
    saveBtn.disabled = true;
    saveBtn.textContent = "Saving…";
    hide("error");

    const result = await sendMessage({
        type: "saveBookmark",
        url,
        title: $("title").value.trim(),
        description: $("description").value.trim(),
        tagNames,
    }).catch(err => ({ success: false, error: err.message }));

    if (result?.success) {
        hide("main");
        show("success");
        setTimeout(() => window.close(), 1200);
    } else {
        const errorEl = $("error");
        errorEl.textContent = result?.error ?? "An unknown error occurred.";
        show("error");
        saveBtn.disabled = false;
        saveBtn.textContent = "Save Bookmark";
    }
});

init();
