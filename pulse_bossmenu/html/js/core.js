/* Bossmenü · core.js
   Helfer: NUI-Aufrufe, ruhige Töne, Skalierung. */
(function () {
    'use strict';

    var IS_BROWSER = typeof window.GetParentResourceName !== 'function';
    var RES = IS_BROWSER ? 'pulse_bossmenu' : window.GetParentResourceName();

    /* NUI-Callbacks antworten mit { ok = true, data = ... } oder { ok = false, error = 'Text' } */
    function api(name, data) {
        var p;
        if (IS_BROWSER) {
            p = new Promise(function (res) {
                setTimeout(function () { res(window.__mockApi ? window.__mockApi(name, data || {}) : { ok: true }); }, 120 + Math.random() * 120);
            });
        } else {
            p = fetch('https://' + RES + '/' + name, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json; charset=UTF-8' },
                body: JSON.stringify(data || {})
            }).then(function (r) { return r.text(); }).then(function (t) {
                try { return JSON.parse(t); } catch (e) { return { ok: true }; }
            });
        }
        return p.then(function (r) {
            if (r && r.ok === false) throw new Error(r.error || 'Fehler');
            return r && r.data !== undefined ? r.data : r;
        });
    }

    /* Ruhige Töne (Web Audio, gedämpft) */
    var ctx = null, soundOn = true;
    function tone(f1, f2, dur, vol, delay) {
        if (!soundOn) return;
        try {
            var C = window.AudioContext || window.webkitAudioContext; if (!C) return;
            ctx = ctx || new C();
            if (ctx.state === 'suspended') ctx.resume();
            var t = ctx.currentTime + (delay || 0);
            var o = ctx.createOscillator(), g = ctx.createGain(), lp = ctx.createBiquadFilter();
            o.type = 'sine';
            o.frequency.setValueAtTime(f1, t);
            o.frequency.exponentialRampToValueAtTime(f2, t + dur);
            lp.type = 'lowpass'; lp.frequency.value = 1700;
            g.gain.setValueAtTime(0.0001, t);
            g.gain.exponentialRampToValueAtTime(vol, t + 0.012);
            g.gain.exponentialRampToValueAtTime(0.0001, t + dur);
            o.connect(lp); lp.connect(g); g.connect(ctx.destination);
            o.start(t); o.stop(t + dur + 0.02);
        } catch (e) { /* stumm */ }
    }
    var SFX = {
        tick: function () { tone(760, 700, 0.04, 0.010); },
        click: function () { tone(680, 600, 0.05, 0.016); },
        ok: function () { tone(560, 560, 0.07, 0.02); tone(840, 840, 0.1, 0.018, 0.07); },
        error: function () { tone(260, 190, 0.18, 0.022); },
        open: function () { tone(360, 520, 0.18, 0.018); },
        invite: function () { tone(660, 660, 0.12, 0.018); tone(990, 990, 0.22, 0.016, 0.12); },
        buy: function () { tone(520, 520, 0.08, 0.02); tone(660, 660, 0.08, 0.02, 0.09); tone(880, 880, 0.18, 0.018, 0.18); }
    };

    function esc(s) {
        return String(s == null ? '' : s).replace(/[&<>"']/g, function (c) {
            return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c];
        });
    }

    function scale() {
        var s = Math.min(window.innerWidth / 1920, window.innerHeight / 1080);
        document.documentElement.style.setProperty('--s', s.toFixed(4));
    }
    window.addEventListener('resize', scale);
    scale();

    window.C = {
        IS_BROWSER: IS_BROWSER,
        api: api,
        play: function (n) { if (SFX[n]) SFX[n](); },
        sound: function (on) { soundOn = !!on; },
        esc: esc
    };
})();
