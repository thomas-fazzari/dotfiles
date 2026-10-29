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
