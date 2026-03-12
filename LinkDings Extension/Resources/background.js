const APP_BUNDLE_ID = "com.mazjap.LinkDings-Client";

browser.runtime.onMessage.addListener((message, sender) => {
    if (message.type === "checkSetup" || message.type === "saveBookmark") {
        return browser.runtime.sendNativeMessage(APP_BUNDLE_ID, message);
    }
});
