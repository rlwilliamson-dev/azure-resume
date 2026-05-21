/* ============================================================
   window.ryan · shared console API
   Loaded on every easter-egg page so ryan.found() / ryan.progress()
   work from any console, not just the home page.
   ============================================================ */
(function () {
  if (window.ryan) return; // do not redefine if already loaded

  const FLAGS = {
    'FLAG{01_the_console_speaks_first}':         '01',
    'FLAG{02_robots_know_more_than_they_admit}': '02',
    'FLAG{03_security_is_first_class}':          '03',
    'FLAG{04_view_source_view_truth}':           '04',
    'FLAG{05_curl_minus_i_is_underrated}':       '05',
    'FLAG{06_rfc_2324_lives_forever}':           '06',
  };
  const FLAG_IDS = ['01','02','03','04','05','06'];

  function totalFound() {
    let n = 0;
    for (const id of FLAG_IDS) {
      try { if (localStorage.getItem('ryan:flag:' + id) === '1') n++; } catch (e) {}
    }
    return n;
  }

  window.ryan = {
    help() {
      console.log(`%c
ryan@rlwilliamson.dev · available commands

  ryan.help()         this output
  ryan.contact()      how to reach me
  ryan.uses()         what I use day-to-day
  ryan.skills()       skill cloud
  ryan.now()          what I'm working on
  ryan.coffee()       more dangerous than it sounds
  ryan.flag()         ...for the cyber-curious
  ryan.found(s)       register a flag you found
  ryan.progress()     how far you've gotten

Tip: there is more to find. Keep poking.`,
        'color: #4cc2ff; font-family: monospace; font-size: 12px;');
    },
    contact() {
      console.log('%cryan@rlwilliamson.dev',          'color: #4ade80; font-family: monospace;');
      console.log('%clinkedin.com/in/rlwilliamson',   'color: #4ade80; font-family: monospace;');
    },
    uses()  { console.log('%c→ https://rlwilliamson.dev/uses', 'color: #4cc2ff;'); },
    now()   { console.log('%c→ https://rlwilliamson.dev/now',  'color: #4cc2ff;'); },
    skills() {
      console.log(`%c
azure · bicep · arm · terraform · powershell · python · bash
github actions · azure devops · cosmos db · entra id · rbac
devsecops · sre · multi-cloud · pfsense · suricata · grapheneos
iso 9001 · people leadership · production operations

Currently leaning into cybersecurity.`,
        'color: #a78bfa; font-family: monospace; font-size: 11px;');
    },
    coffee() {
      console.log("%c418 I'm a teapot.", 'color: #f7768e; font-family: monospace;');
      console.log('%c→ see /coffee',     'color: #565f89; font-family: monospace; font-size: 11px;');
    },
    flag() {
      console.log('%cFLAG{01_the_console_speaks_first}', 'color: #e0af68; font-family: monospace; font-size: 13px;');
      console.log(`%c
You found one. There are more.
Register what you find with ryan.found('FLAG{...}') and check ryan.progress() any time.

Next: 'allowed' is a hint. So is 'disallowed'.`,
        'color: #7d8595; font-family: monospace; font-size: 11px;');
    },
    found(input) {
      const id = FLAGS[String(input || '').trim()];
      if (!id) {
        console.log('%cthat one is not on the list. check the spelling (the curly braces matter).', 'color: #f87171; font-family: monospace;');
        return;
      }
      try { localStorage.setItem('ryan:flag:' + id, '1'); } catch (e) {}
      const total = totalFound();
      console.log('%cregistered ' + id + '. ' + total + '/6.', 'color: #4ade80; font-family: monospace; font-size: 12px;');
      if (total === 6) {
        console.log('%call six. one route holds the reveal. the last flag spells it out.', 'color: #facc15; font-family: monospace;');
      }
    },
    progress() {
      const found = FLAG_IDS.filter(id => {
        try { return localStorage.getItem('ryan:flag:' + id) === '1'; } catch (e) { return false; }
      });
      const missing = FLAG_IDS.filter(id => !found.includes(id));
      console.log('%cprogress: ' + found.length + '/6', 'color: #4cc2ff; font-family: monospace; font-size: 13px;');
      if (found.length)   console.log('%cfound:        ' + found.join(', '),   'color: #4ade80; font-family: monospace;');
      if (missing.length) console.log('%cstill missing: ' + missing.join(', '), 'color: #7d8595; font-family: monospace;');
      if (found.length === 6) {
        console.log('%cthe final step is a route. the last flag spells it out.', 'color: #facc15; font-family: monospace;');
      }
    },
  };
})();
