// Style Scripts
//
// This script is loaded by the main page and contains all scripts related to
// the visual layout and style of the page. Loading is usually deferred via
// `defer`.
//
// The main part of this script is a `DOMContentLoaded` handler that registers
// event-handlers and caches DOM element references.

document.addEventListener(
        "DOMContentLoaded",
        () => {
                // Cache DOM elements to avoid lookups in event handlers.
                const nav = document.getElementById("nav");
                const nav_checkbox = document.getElementById("nav-checkbox");

                // Navigation Close Triggers
                //
                // Watch for ESC (keycode 27) events and close the navigation
                // when triggered. Additionally, watch for CLICK events outside
                // of the navigation element and close the navigation as well.
                //
                // XXX: For better accessibility CLICK handling should be
                //      avoided, yet no nice alternative exists.
                document.addEventListener("keydown", event => {
                        if (event.keyCode == 27)
                                nav_checkbox.checked = 0;
                });
                document.addEventListener("click", event => {
                        if (!nav.contains(event.target))
                                nav_checkbox.checked = 0;
                });
        },
        {
                once: true,
        },
);
