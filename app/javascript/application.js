// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "./controllers"
import * as bootstrap from "bootstrap"
import party from "party-js";

let popoverTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="popover"]'))
let popoverList = popoverTriggerList.map(function (popoverTriggerEl) {
    return new bootstrap.Popover(popoverTriggerEl)
})

// This section is to watch to see if the game over section is displayed so that
// the confetti cannon can be popped.
//
// Copied solution from this SO post to get it working:
//   - https://stackoverflow.com/questions/3219758/detect-changes-in-the-dom/14570614#14570614
const observeDOM = (function () {
    var MutationObserver = window.MutationObserver || window.WebKitMutationObserver;

    return function (obj, callback) {
        if (!obj || obj.nodeType !== 1) return;

        // define a new observer
        var mutationObserver = new MutationObserver(callback)

        // have the observer observe for changes in children
        mutationObserver.observe(obj, {childList: true, subtree: true})
        return mutationObserver
    }
})();

observeDOM( document.body, function(m){
    m.forEach( record => {
        if (record.addedNodes.length > 0) {
            record.addedNodes.forEach( addedNode => {
                if (addedNode.id === "game_over_stats") {
                    party.confetti(addedNode, {count: 200})
                }
            })
        }
    })
});