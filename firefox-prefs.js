// keep just one content process so Firefox doesn't eat too much memory
// the sandbox can also be disabled with MOZ_DISABLE_CONTENT_SANDBOX=1, which noticeably improves performance
pref("browser.tabs.remote.separateFileUriProcess", false, locked);
pref("browser.tabs.remote.separatePrivilegedContentProcess", false, locked);
pref("browser.tabs.remote.separatePrivilegedMozillaWebContentProcess", false, locked);
pref("browser.opaqueResponseBlocking.javascriptValidator", false, locked);
pref("network.process.enabled", false, locked);
pref("layers.gpu-process.enabled", false, locked);
pref("fission.autostart", false, locked);
pref("dom.ipc.forkserver.enable", false, locked);
pref("dom.ipc.processCount", 1, locked);
pref("dom.ipc.keepProcessesAlive.privilegedabout", 0, locked);

// sandbox level 3 and above forbids access to local files, so use level 2 to open local files without a separate file:// process
// has no effect with MOZ_DISABLE_CONTENT_SANDBOX=1
pref("security.sandbox.content.level", 2, locked);

// take CPU performance back
pref("javascript.options.spectre.index_masking", false, locked);
pref("javascript.options.spectre.object_mitigations", false, locked);
pref("javascript.options.spectre.string_mitigations", false, locked);
pref("javascript.options.spectre.value_masking", false, locked);

// Russian
pref("intl.accept_languages", "ru,ru-ru,en-us,en", locked);
pref("intl.locale.requested", "ru", locked);

// don't show the warning on about:config
pref("browser.aboutConfig.showWarning", false, locked);

// UI density
pref("browser.uidensity", 1, locked);

// use CSD
pref("browser.tabs.inTitlebar", 1, locked);

// compact mode
pref("browser.compactmode.show", true, locked);

// always show the downloads button
pref("browser.download.autohideButton", false, locked);

// restore the session on startup and don't ask when closing the window
pref("browser.startup.page", 3, locked);
pref("browser.tabs.warnOnClose", false, locked);

// disable the cache to save memory
pref("browser.sessionhistory.max_total_viewers", 0, locked);

// personalized extension recommendations
pref("browser.discovery.enabled", false, locked);
pref("browser.newtabpage.activity-stream.asrouter.userprefs.cfr.addons", false, locked);
pref("browser.newtabpage.activity-stream.asrouter.userprefs.cfr.features", false, locked);

// ads
pref("browser.newtabpage.activity-stream.showSponsored", false, locked);
pref("browser.newtabpage.activity-stream.showSponsoredCheckboxes", false, locked);
pref("browser.newtabpage.activity-stream.showSponsoredTopSites", false, locked);

// terribly annoying prompts
pref("permissions.default.geo", 2, locked);

// WebRTC too
pref("media.peerconnection.enabled", false, locked);

// all kinds of telemetry, just so it doesn't waste traffic
pref("datareporting.healthreport.uploadEnabled", false, locked);
pref("browser.safebrowsing.blockedURIs.enabled", false, locked);
pref("browser.safebrowsing.downloads.enabled", false, locked);
pref("browser.safebrowsing.malware.enabled", false, locked);
pref("browser.safebrowsing.phishing.enabled", false, locked);
pref("browser.newtabpage.activity-stream.feeds.telemetry", false, locked);
pref("browser.newtabpage.activity-stream.telemetry", false, locked);

// improve privacy
pref("privacy.trackingprotection.enabled", true, locked);
pref("privacy.globalprivacycontrol.enabled", true, locked);

// disable speculative requests, no need for them
pref("network.dns.disablePrefetch", true, locked);
pref("network.prefetch-next", false, locked);
pref("network.http.speculative-parallel-limit", 0, locked);

// disable video and audio autoplay
pref("media.autoplay.default", 5, locked);
pref("media.autoplay.block-event.enabled", true, locked);
pref("media.autoplay.block-webaudio", true, locked);

// PiP everywhere
pref("media.videocontrols.picture-in-picture.respect-disablePictureInPicture", false, locked);

// annoying when releasing the mouse button activates a menu item
pref("ui.context_menus.after_mouseup", true, locked);
