// Personal BetterZen overrides, inserted under "MY OVERRIDES" by update-userjs.pl
// https://github.com/yokoffing/Betterfox/wiki/Common-Overrides
// https://github.com/yokoffing/Betterfox/wiki/Optional-Hardening

// Bitwarden handles passwords, addresses and cards
user_pref("signon.rememberSignons", false);
user_pref("extensions.formautofill.addresses.enabled", false);
user_pref("extensions.formautofill.creditCards.enabled", false);

// URL bar search suggestions
user_pref("browser.search.suggest.enabled", true);

user_pref("browser.ai.control.default", "blocked");

// No DoH: Tailscale MagicDNS and ProtonVPN resolve names
user_pref("network.trr.mode", 5);

// Smoothfox natural smooth scrolling v3, tuned for a mouse wheel
// https://github.com/yokoffing/Betterfox/blob/main/Smoothfox.js
user_pref("apz.overscroll.enabled", true);
user_pref("general.smoothScroll", true);
user_pref("general.smoothScroll.msdPhysics.continuousMotionMaxDeltaMS", 12);
user_pref("general.smoothScroll.msdPhysics.enabled", true);
user_pref("general.smoothScroll.msdPhysics.motionBeginSpringConstant", 600);
user_pref("general.smoothScroll.msdPhysics.regularSpringConstant", 650);
user_pref("general.smoothScroll.msdPhysics.slowdownMinDeltaMS", 25);
user_pref("general.smoothScroll.msdPhysics.slowdownMinDeltaRatio", "2");
user_pref("general.smoothScroll.msdPhysics.slowdownSpringConstant", 250);
user_pref("general.smoothScroll.currentVelocityWeighting", "1");
user_pref("general.smoothScroll.stopDecelerationWeighting", "1");
user_pref("mousewheel.default.delta_multiplier_y", 300); // 250-400
