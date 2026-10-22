/* Bossmenü · app.js
   Alle Nachrichten und Callbacks stehen in LIESMICH.txt. */
(function () {
    'use strict';

    var CONFIG = {
        logo: 'img/logo.png',            // eigenes Logo, ohne Datei erscheint ein P
        brand: 'PULSE ROLEPLAY',
        currency: '$',
        quick: [1000, 5000, 10000, 50000],
        rankColors: ['#9AA6B8', '#8FD3FF', '#5FD3C6', '#7FE0A8', '#FFB85C', '#C9A6FF', '#FF8FB8', '#FFE38A'],
        inviteTimeout: 30                // Sekunden, falls der Server keinen Wert schickt
    };

    var $ = function (id) { return document.getElementById(id); };
    var esc = C.esc;
    var win = $('win'), body = $('body');

    var S = {
        open: false, view: 'home', q: '', mFilter: 'all', lFilter: 'all', amount: '',
        faction: '', me: null, grades: [], members: [], balance: 0, week: null,
        tx: [], logs: [], settings: {}, perms: {}, dirty: false
    };

    function money(n) { return CONFIG.currency + Math.round(Number(n) || 0).toLocaleString('de-DE'); }
    function initials(n) { return String(n || '?').split(' ').map(function (x) { return x.charAt(0); }).join('').slice(0, 2).toUpperCase(); }
    function grade(g) { for (var i = 0; i < S.grades.length; i++) if (S.grades[i].grade === g) return S.grades[i]; return { grade: g, label: 'Rang ' + g, salary: 0 }; }
    function gIndex(g) { for (var i = 0; i < S.grades.length; i++) if (S.grades[i].grade === g) return i; return 0; }
    function color(g) { return CONFIG.rankColors[gIndex(g) % CONFIG.rankColors.length]; }
    function maxGrade() { return S.grades.length ? S.grades[S.grades.length - 1].grade : 0; }
    function minGrade() { return S.grades.length ? S.grades[0].grade : 0; }
    function allowed(k) { return S.perms[k] !== false; }

    var ICON = {
        back: '<path d="M15 5l-7 7 7 7"/>',
        search: '<circle cx="11" cy="11" r="7"/><path d="M20 20l-4-4"/>',
        hire: '<circle cx="9" cy="8" r="4"/><path d="M2 21c0-4 3-7 7-7s7 3 7 7M19 8v6M16 11h6"/>',
        fire: '<circle cx="9" cy="8" r="4"/><path d="M2 21c0-4 3-7 7-7s7 3 7 7M16 9l5 5M21 9l-5 5"/>',
        promote: '<path d="M12 19V5M5 12l7-7 7 7"/>',
        demote: '<path d="M12 5v14M5 12l7 7 7-7"/>',
        deposit: '<path d="M12 4v12M6 10l6 6 6-6M5 20h14"/>',
        withdraw: '<path d="M12 16V4M6 10l6-6 6 6M5 20h14"/>',
        settings: '<circle cx="12" cy="12" r="3"/><path d="M19 12h2M3 12h2M12 3v2M12 19v2M17 7l1.4-1.4M5.6 18.4L7 17M17 17l1.4 1.4M5.6 5.6L7 7"/>',
        lock: '<rect x="5" y="11" width="14" height="10" rx="2"/><path d="M8 11V8a4 4 0 0 1 8 0v3"/>',
        check: '<path d="M5 12.5l4.5 4.5L19 7.5"/>',
        bang: '<path d="M12 7v6M12 17v.01"/>'
    };
    function ic(name, size, sw) {
        return '<svg width="' + (size || 16) + '" height="' + (size || 16) + '" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="' + (sw || 2.2) + '" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">' + ICON[name] + '</svg>';
    }
    var KIND = {
        hire: ['#7FE0A8', 'members'], fire: ['#FF7A8A', 'members'], promote: ['#8FD3FF', 'members'], demote: ['#FFB85C', 'members'],
        deposit: ['#8FD3FF', 'funds'], withdraw: ['#FFB85C', 'funds'], settings: ['#C9A6FF', 'settings']
    };

    /* ---------- Logo ---------- */
    (function () {
        var l = $('logo');
        $('brandName').textContent = CONFIG.brand;
        l.classList.add('fb');
        if (!CONFIG.logo) return;
        var im = new Image(); im.alt = '';
        im.onload = function () { l.classList.remove('fb'); l.insertBefore(im, l.firstChild); };
        im.src = CONFIG.logo;
    })();

    /* ---------- Hinweise ---------- */
    function toast(text, type) {
        var box = $('toasts'), el = document.createElement('div');
        el.className = 'toast ' + (type || 'success');
        el.innerHTML = '<span class="t-ic"><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="3" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">' + (type === 'error' ? ICON.bang : ICON.check) + '</svg></span><span>' + esc(text) + '</span>';
        box.appendChild(el);
        while (box.children.length > 3) box.firstChild.remove();
        setTimeout(function () { el.classList.add('out'); setTimeout(function () { el.remove(); }, 300); }, 3000);
    }
    function fail(e) { toast(e && e.message ? e.message : 'Fehler', 'error'); C.play('error'); }

    // Antworten des Servers übernehmen (alles optional)
    function apply(d) {
        if (!d || typeof d !== 'object') return;
        if (d.members) S.members = d.members;
        if (d.grades) S.grades = d.grades.slice().sort(function (a, b) { return a.grade - b.grade; });
        if (d.balance != null) S.balance = Number(d.balance) || 0;
        if (d.transactions) S.tx = d.transactions;
        if (d.logs) S.logs = d.logs;
        if (d.settings) S.settings = d.settings;
        if (d.weekChange != null) S.week = d.weekChange;
    }

    /* ---------- Ansichten ---------- */
    var TITLES = {
        home: ['Übersicht', 'Verwalte deine Fraktion an einem Ort'],
        members: ['Mitglieder', 'Ränge, Gehälter und Status deiner Mitglieder'],
        funds: ['Firmenkasse', 'Ein- und Auszahlungen und jede Buchung im Blick'],
        settings: ['Einstellungen', 'Ränge, Gehälter und Regeln der Fraktion'],
        logs: ['Protokoll', 'Alle Aktionen und Änderungen der letzten Tage']
    };

    function go(view) {
        if (view !== 'home' && !allowed(view)) { toast('Dafür fehlt dir die Berechtigung', 'error'); C.play('error'); return; }
        S.view = view;
        var sub = document.querySelector('.sub');
        sub.classList.toggle('home', view === 'home');
        ['viewTitle', 'viewDesc'].forEach(function (id, i) {
            var el = $(id); el.textContent = TITLES[view][i];
            el.style.animation = 'none'; void el.offsetWidth; el.style.animation = '';
        });
        render(true);
        C.play('click');
    }

    function render(anim) {
        var html = '';
        if (S.view === 'home') html = vHome();
        else if (S.view === 'members') html = vMembers();
        else if (S.view === 'funds') html = vFunds();
        else if (S.view === 'settings') html = vSettings();
        else if (S.view === 'logs') html = vLogs();
        body.innerHTML = '<div class="view"' + (anim ? '' : ' style="animation:none"') + '>' + html + '</div>';
        if (S.view === 'members') { var q = $('q'); if (q && document.activeElement !== q && S.q) { q.value = S.q; } }
    }

    function av(m, sm) { return '<i class="av' + (sm ? ' sm' : '') + '">' + esc(initials(m.name)) + '</i>'; }
    function rk(g, pop) { return '<span class="rk' + (pop ? ' pop' : '') + '">' + esc(grade(g).label) + '</span>'; }

    function vHome() {
        var on = S.members.filter(function (m) { return m.online; });
        var pay = S.members.reduce(function (a, m) { return a + (Number(grade(m.grade).salary) || 0); }, 0);
        var duty = on.slice(0, 4).map(function (m, i) {
            return '<div class="row" style="--i:' + i + '">' + av(m, true) + '<span class="nm">' + esc(m.name) + '</span>' + rk(m.grade) + '</div>';
        }).join('') || '<p class="empty">Gerade ist niemand im Dienst.</p>';
        var tiles = [
            { k: 'funds', art: 'safe', t: 'Firmenkasse', d: 'Ein- und Auszahlungen und jede Buchung der Fraktionskasse.', b: money(S.balance) },
            { k: 'settings', art: 'tools', t: 'Einstellungen', d: 'Ränge, Gehälter und Regeln an deine Fraktion anpassen.', b: S.grades.length + ' Ränge' },
            { k: 'logs', art: 'logs', t: 'Protokoll', d: 'Klare Übersicht über alle Aktionen und letzten Änderungen.', b: S.logs.length + ' Einträge' }
        ].map(function (t, i) {
            var ok = allowed(t.k);
            return '<div class="card hov tile" style="--i:' + i + '"><span class="badge">' + esc(t.b) + '</span>' +
                '<svg class="art" width="112" height="112" viewBox="0 0 120 120" aria-hidden="true"><use href="#art-' + t.art + '"/></svg>' +
                '<h3>' + t.t + '</h3><p>' + t.d + '</p>' +
                '<button type="button" class="btn soft" data-go="' + t.k + '"' + (ok ? '' : ' disabled') + '>' + (ok ? 'Öffnen' : ic('lock', 15) + 'Keine Berechtigung') + '</button></div>';
        }).join('');
        var mOk = allowed('members');
        return '<div class="home-grid">' +
            '<div class="card hov hero"><i class="hero-glow"></i>' +
            '<div class="hero-l"><svg class="art" width="130" height="130" viewBox="0 0 120 120" aria-hidden="true"><use href="#art-members"/></svg>' +
            '<h2>Mitglieder</h2><p>Ränge, Gehälter und Status aller Mitglieder deiner Fraktion verwalten.</p>' +
            '<button type="button" class="btn" data-go="members"' + (mOk ? '' : ' disabled') + '>' + (mOk ? 'Öffnen' : ic('lock', 15) + 'Keine Berechtigung') + '</button></div>' +
            '<div class="hero-r"><div class="stats">' +
            '<div class="stat"><span>Mitglieder</span><b>' + S.members.length + '</b></div>' +
            '<div class="stat"><span>Im Dienst</span><b class="ice">' + on.length + '</b></div>' +
            '<div class="stat"><span>Gehälter / Zahltag</span><b>' + money(pay) + '</b></div></div>' +
            '<span class="mk" style="margin-top:4px">GERADE IM DIENST</span><div class="duty">' + duty + '</div></div></div>' +
            '<div class="tiles3">' + tiles + '</div></div>';
    }

    var popId = null;
    function vMembers() {
        var q = S.q.toLowerCase();
        var rows = S.members.filter(function (m) {
            return (S.mFilter === 'all' || m.online) && String(m.name).toLowerCase().indexOf(q) !== -1;
        }).sort(function (a, b) { return b.grade - a.grade || String(a.name).localeCompare(b.name); });
        var list = rows.map(function (m, i) {
            var self = S.me != null && m.identifier === S.me;
            var acts = self ? '<span class="you">Du</span>' :
                '<button type="button" class="icb up" data-act="promote" data-id="' + esc(m.identifier) + '" aria-label="Befördern" title="Befördern"' + (m.grade >= maxGrade() ? ' disabled' : '') + '>' + ic('promote', 16, 2.4) + '</button>' +
                '<button type="button" class="icb" data-act="demote" data-id="' + esc(m.identifier) + '" aria-label="Degradieren" title="Degradieren"' + (m.grade <= minGrade() ? ' disabled' : '') + '>' + ic('demote', 16, 2.4) + '</button>' +
                '<button type="button" class="icb del" data-act="fire" data-id="' + esc(m.identifier) + '" aria-label="Entlassen" title="Entlassen">' + ic('fire', 16) + '</button>';
            return '<div class="row mrow" data-row="' + esc(m.identifier) + '" style="--i:' + Math.min(i, 12) + '">' +
                '<span class="who">' + av(m) + '<span class="wt"><b>' + esc(m.name) + '</b><small>' + (m.since ? 'Dabei seit ' + esc(m.since) : '') + '</small></span></span>' +
                '<span>' + rk(m.grade, popId === m.identifier) + '</span>' +
                '<span class="mono">' + money(grade(m.grade).salary) + '</span>' +
                '<span class="st' + (m.online ? ' on' : '') + '"><i></i>' + (m.online ? 'Im Dienst' : 'Außer Dienst') + '</span>' +
                '<span class="acts">' + acts + '</span></div>';
        }).join('') || '<p class="empty">Keine Mitglieder gefunden.</p>';
        popId = null;
        return '<div class="bar">' +
            '<label class="field">' + ic('search', 16) + '<input id="q" type="text" placeholder="Mitglied suchen" aria-label="Mitglied suchen" spellcheck="false" value="' + esc(S.q) + '"></label>' +
            '<div class="pills">' + [['all', 'Alle'], ['on', 'Im Dienst']].map(function (f) {
                return '<button type="button" class="pill' + (S.mFilter === f[0] ? ' on' : '') + '" data-mf="' + f[0] + '">' + f[1] + '</button>';
            }).join('') + '</div><span class="sp"></span>' +
            '<button type="button" class="btn" id="btnHire">' + ic('hire', 18) + 'Person einstellen</button></div>' +
            '<div class="th"><span>NAME</span><span>RANG</span><span>GEHALT</span><span>STATUS</span><span>AKTIONEN</span></div>' +
            '<div class="list scroll" id="mlist">' + list + '</div>';
    }

    function vFunds() {
        var tx = S.tx.map(function (x, i) {
            var inn = x.type === 'in';
            return '<div class="row tx" style="--i:' + Math.min(i, 12) + '"><span class="ic" style="color:' + (inn ? '#8FD3FF' : '#FFB85C') + '">' + ic(inn ? 'deposit' : 'withdraw', 16, 2.4) + '</span>' +
                '<span class="tx-t"><b>' + esc(x.note || (inn ? 'Einzahlung' : 'Auszahlung')) + '</b><span>' + esc(x.who || '') + (x.time ? ' · ' + esc(x.time) : '') + '</span></span>' +
                '<span class="tx-a' + (inn ? ' in' : '') + '">' + (inn ? '+ ' : '− ') + money(x.amount) + '</span></div>';
        }).join('') || '<p class="empty">Noch keine Buchungen.</p>';
        return '<div class="funds">' +
            '<div class="card vault"><div class="vault-top"><svg class="art" width="120" height="120" viewBox="0 0 120 120" aria-hidden="true"><use href="#art-safe"/></svg>' +
            '<div><span>Kontostand Firmenkasse</span><b class="bal" id="bal">' + money(S.balance) + '</b>' + (S.week ? '<i class="wk" style="font-style:normal">' + esc(S.week) + '</i>' : '') + '</div></div>' +
            '<div class="amt"><label for="amt">Betrag</label><div class="amt-in"><span>' + esc(CONFIG.currency) + '</span><input id="amt" type="text" inputmode="numeric" placeholder="0" value="' + esc(S.amount) + '"></div>' +
            '<div class="quick">' + CONFIG.quick.map(function (v) { return '<button type="button" data-q="' + v + '">' + money(v) + '</button>'; }).join('') + '</div>' +
            '<span class="ferr" id="ferr"></span>' +
            '<div class="two"><button type="button" class="btn" data-fund="deposit">' + ic('deposit', 18, 2.4) + 'Einzahlen</button>' +
            '<button type="button" class="btn grey" data-fund="withdraw">' + ic('withdraw', 18, 2.4) + 'Auszahlen</button></div></div></div>' +
            '<div class="card side"><div class="side-h"><span class="h3">Buchungen</span><span>' + S.tx.length + ' Einträge</span></div>' +
            '<div class="list scroll" style="margin-top:0">' + tx + '</div></div></div>';
    }

    var TOGGLES = [
        ['payFromSociety', 'Gehalt aus der Firmenkasse', 'Zahltage werden von der Kasse abgebucht'],
        ['offDutyPay', 'Gehalt außer Dienst', 'Auch Mitglieder außer Dienst bekommen Gehalt'],
        ['notifyAll', 'Änderungen melden', 'Alle im Dienst sehen Beförderungen']
    ];
    function vSettings() {
        var rows = S.grades.slice().reverse().map(function (g, i) {
            var n = S.members.filter(function (m) { return m.grade === g.grade; }).length;
            return '<div class="row rrow" style="--i:' + i + '"><span class="lvl">' + (gIndex(g.grade) + 1) + '</span>' +
                '<span class="rn"><i></i>' + esc(g.label) + '</span>' +
                '<span class="mono" style="font-size:13px;color:rgba(230,240,251,.7)">' + n + '</span>' +
                '<label class="money-in"><span>' + esc(CONFIG.currency) + '</span><input type="text" inputmode="numeric" data-sal="' + g.grade + '" aria-label="Gehalt ' + esc(g.label) + '" value="' + (Number(g.salary) || 0) + '"></label></div>';
        }).join('');
        var tg = TOGGLES.filter(function (t) { return S.settings[t[0]] !== undefined; }).map(function (t) {
            return '<button type="button" class="tg" role="switch" data-tg="' + t[0] + '" aria-checked="' + (!!S.settings[t[0]]) + '"><span><b>' + t[1] + '</b><small>' + t[2] + '</small></span><i class="sw"></i></button>';
        }).join('');
        return '<div class="sets">' +
            '<div class="card side"><div class="side-h"><span class="h3">Ränge &amp; Gehälter</span><span>Gehalt pro Zahltag</span></div>' +
            '<div class="rth"><span>STUFE</span><span>NAME</span><span>MITGLIEDER</span><span>GEHALT</span></div>' +
            '<div class="list scroll" style="margin-top:0">' + rows + '</div></div>' +
            '<div class="right">' + (tg ? '<div class="card side" style="gap:6px"><span class="h3" style="margin-bottom:8px">Allgemein</span>' + tg + '</div>' : '') +
            '<span class="sp"></span><span class="saved" id="saved">' + (S.dirty ? 'Ungespeicherte Änderungen' : '') + '</span>' +
            '<button type="button" class="btn save-btn" id="btnSave">SPEICHERN</button></div></div>';
    }

    function vLogs() {
        var rows = S.logs.filter(function (l) { return S.lFilter === 'all' || (KIND[l.kind] || [])[1] === S.lFilter; }).map(function (l, i) {
            var k = KIND[l.kind] || ['#8FD3FF', 'other'];
            return '<div class="row lrow" style="--i:' + Math.min(i, 14) + '"><span class="ic" style="color:' + k[0] + '">' + ic(ICON[l.kind] ? l.kind : 'settings', 18) + '</span>' +
                '<span class="tx-t">' + esc(l.text) + '</span>' + (l.who ? '<small>von <b>' + esc(l.who) + '</b></small>' : '') + '<time>' + esc(l.time || '') + '</time></div>';
        }).join('') || '<p class="empty">Keine Einträge.</p>';
        return '<div class="pills" style="align-self:flex-start">' + [['all', 'Alle'], ['members', 'Mitglieder'], ['funds', 'Kasse'], ['settings', 'Einstellungen']].map(function (f) {
            return '<button type="button" class="pill' + (S.lFilter === f[0] ? ' on' : '') + '" data-lf="' + f[0] + '">' + f[1] + '</button>';
        }).join('') + '</div><div class="list scroll" style="margin-top:14px">' + rows + '</div>';
    }

    /* ---------- Dialoge ---------- */
    function modal(html) {
        closeModal(true);
        var m = document.createElement('div');
        m.className = 'modal'; m.id = 'modal';
        m.innerHTML = '<div class="dlg" role="dialog" aria-modal="true">' + html + '</div>';
        win.appendChild(m);
        m.addEventListener('mousedown', function (e) { if (e.target === m) closeModal(); });
        return m;
    }
    function closeModal(now) {
        var m = $('modal'); if (!m) return;
        if (now) { m.remove(); return; }
        m.classList.add('out'); m.id = '';
        setTimeout(function () { m.remove(); }, 200);
    }

    function confirmFire(m) {
        var d = modal('<h3>' + esc(m.name) + ' entlassen?</h3><p>' + esc(m.name) + ' verliert sofort den Rang <b style="color:#E6F0FB">' + esc(grade(m.grade).label) + '</b> und alle Rechte in der Fraktion.</p>' +
            '<div class="two"><button type="button" class="btn grey" data-x>Abbrechen</button><button type="button" class="btn red" data-ok>Entlassen</button></div>');
        d.querySelector('[data-x]').onclick = function () { closeModal(); };
        d.querySelector('[data-ok]').onclick = function () {
            closeModal();
            var row = document.querySelector('[data-row="' + CSS.escape(String(m.identifier)) + '"]');
            C.api('fire', { identifier: m.identifier }).then(function (r) {
                if (row) row.classList.add('out');
                setTimeout(function () {
                    if (r && r.members) apply(r); else S.members = S.members.filter(function (x) { return x.identifier !== m.identifier; });
                    apply({ logs: r && r.logs });
                    render(false);
                }, 260);
                toast(m.name + ' wurde entlassen'); C.play('ok');
            }).catch(fail);
        };
    }

    function openHire() {
        var d = modal('<h3>Person einstellen</h3><p>Spieler in deiner Nähe. Sie bekommen eine Einladung und können annehmen oder ablehnen.</p><div class="pick scroll" id="near"><p class="empty">Suche Spieler …</p></div>' +
            '<div class="two" style="grid-template-columns:1fr"><button type="button" class="btn grey" data-x>Schließen</button></div>');
        d.querySelector('[data-x]').onclick = function () { closeModal(); };
        C.api('getNearbyPlayers', {}).then(function (list) {
            var box = $('near'); if (!box) return;
            list = Array.isArray(list) ? list : (list && list.players) || [];
            if (!list.length) { box.innerHTML = '<p class="empty">Niemand in deiner Nähe.</p>'; return; }
            var opts = S.grades.map(function (g) { return '<option value="' + g.grade + '">' + esc(g.label) + '</option>'; }).join('');
            box.innerHTML = list.map(function (p, i) {
                return '<div class="row prow" style="--i:' + i + '"><span>' + esc(p.name) + '</span><small>ID ' + esc(p.id) + '</small>' +
                    '<select class="gsel" data-g="' + esc(p.id) + '" aria-label="Rang für ' + esc(p.name) + '">' + opts + '</select>' +
                    '<button type="button" class="btn" data-inv="' + esc(p.id) + '" data-name="' + esc(p.name) + '">Einladen</button></div>';
            }).join('');
        }).catch(function (e) { var box = $('near'); if (box) box.innerHTML = '<p class="empty">' + esc(e.message) + '</p>'; });
        d.addEventListener('click', function (e) {
            var b = e.target.closest('[data-inv]'); if (!b) return;
            var id = b.getAttribute('data-inv'), sel = d.querySelector('[data-g="' + CSS.escape(id) + '"]');
            b.disabled = true;
            C.api('hire', { id: isNaN(+id) ? id : +id, grade: sel ? +sel.value : minGrade() }).then(function (r) {
                apply(r);
                b.textContent = 'Gesendet';
                toast('Einladung an ' + b.getAttribute('data-name') + ' gesendet'); C.play('ok');
            }).catch(function (er) { b.disabled = false; fail(er); });
        });
    }

    /* ---------- Klicks ---------- */
    body.addEventListener('click', function (e) {
        var t = e.target.closest('button'); if (!t || t.disabled) return;
        if (t.hasAttribute('data-go')) return go(t.getAttribute('data-go'));
        if (t.hasAttribute('data-mf')) { S.mFilter = t.getAttribute('data-mf'); render(false); C.play('click'); return; }
        if (t.hasAttribute('data-lf')) { S.lFilter = t.getAttribute('data-lf'); render(false); C.play('click'); return; }
        if (t.id === 'btnHire') return openHire();
        if (t.hasAttribute('data-act')) {
            var id = t.getAttribute('data-id'), act = t.getAttribute('data-act');
            var m = S.members.filter(function (x) { return String(x.identifier) === id; })[0]; if (!m) return;
            if (act === 'fire') return confirmFire(m);
            var dir = act === 'promote' ? 1 : -1;
            var idx = gIndex(m.grade) + dir; if (idx < 0 || idx >= S.grades.length) return;
            var target = S.grades[idx];
            t.disabled = true;
            C.api(act, { identifier: m.identifier, grade: target.grade }).then(function (r) {
                if (r && r.members) apply(r); else m.grade = target.grade;
                apply({ logs: r && r.logs });
                popId = m.identifier; render(false);
                toast(m.name + ' ist jetzt ' + target.label); C.play('ok');
            }).catch(function (er) { t.disabled = false; fail(er); });
            return;
        }
        if (t.hasAttribute('data-q')) { S.amount = t.getAttribute('data-q'); $('amt').value = Number(S.amount).toLocaleString('de-DE'); $('ferr').textContent = ''; C.play('tick'); return; }
        if (t.hasAttribute('data-fund')) {
            var kind = t.getAttribute('data-fund');
            var amt = parseInt(String($('amt').value).replace(/\D/g, ''), 10) || 0;
            if (!amt) { $('ferr').textContent = 'Gib einen Betrag ein'; C.play('error'); return; }
            if (kind === 'withdraw' && amt > S.balance) { $('ferr').textContent = 'So viel ist nicht in der Kasse'; C.play('error'); return; }
            t.disabled = true;
            C.api(kind, { amount: amt }).then(function (r) {
                if (r && r.balance != null) apply(r); else { S.balance += kind === 'deposit' ? amt : -amt; apply(r); }
                S.amount = '';
                render(false);
                var b = $('bal'); if (b) { b.classList.add('bump'); }
                toast(money(amt) + (kind === 'deposit' ? ' eingezahlt' : ' ausgezahlt')); C.play('ok');
            }).catch(function (er) { t.disabled = false; fail(er); });
            return;
        }
        if (t.hasAttribute('data-tg')) {
            var k = t.getAttribute('data-tg');
            S.settings[k] = !S.settings[k]; S.dirty = true;
            t.setAttribute('aria-checked', String(!!S.settings[k]));
            $('saved').textContent = 'Ungespeicherte Änderungen';
            C.play('tick'); return;
        }
        if (t.id === 'btnSave') {
            t.disabled = true;
            C.api('saveSettings', {
                grades: S.grades.map(function (g) { return { grade: g.grade, salary: Number(g.salary) || 0 }; }),
                settings: S.settings
            }).then(function (r) {
                apply(r); S.dirty = false;
                render(false);
                $('saved').textContent = 'Gespeichert';
                toast('Einstellungen gespeichert'); C.play('ok');
            }).catch(function (er) { t.disabled = false; fail(er); });
        }
    });
    body.addEventListener('input', function (e) {
        var t = e.target;
        if (t.id === 'q') {
            S.q = t.value;
            var pos = t.selectionStart;
            render(false);
            var q = $('q'); q.focus(); q.setSelectionRange(pos, pos);
        } else if (t.id === 'amt') {
            var n = t.value.replace(/\D/g, '').slice(0, 10);
            S.amount = n;
            t.value = n ? Number(n).toLocaleString('de-DE') : '';
            $('ferr').textContent = '';
        } else if (t.hasAttribute('data-sal')) {
            var v = t.value.replace(/\D/g, '').slice(0, 7);
            t.value = v;
            var g = grade(+t.getAttribute('data-sal'));
            g.salary = +v || 0; S.dirty = true;
            $('saved').textContent = 'Ungespeicherte Änderungen';
        }
    });

    $('btnBack').addEventListener('click', function () { go('home'); });
    $('btnExit').addEventListener('click', function () { close(true); });

    /* ---------- Öffnen / Schließen ---------- */
    // Anzeige-Einstellungen aus der config.lua übernehmen (brand, currency, quick, rankColors, inviteTimeout, logo)
    function applyUi(ui) {
        if (!ui || typeof ui !== 'object') return;
        ['brand', 'currency', 'quick', 'rankColors', 'inviteTimeout'].forEach(function (k) { if (ui[k] != null) CONFIG[k] = ui[k]; });
        $('brandName').textContent = CONFIG.brand;
    }

    function open(d) {
        applyUi(d.ui);
        S.faction = (d.faction && (d.faction.label || d.faction.name)) || d.faction || 'Fraktion';
        S.me = d.me != null ? d.me : null;
        S.perms = d.permissions || {};
        S.members = []; S.tx = []; S.logs = []; S.settings = {}; S.grades = [];
        S.balance = 0; S.week = null; S.q = ''; S.mFilter = 'all'; S.lFilter = 'all'; S.amount = ''; S.dirty = false;
        apply(d);
        $('facName').textContent = S.faction;
        S.view = 'home';
        document.querySelector('.sub').classList.add('home');
        $('viewTitle').textContent = TITLES.home[0]; $('viewDesc').textContent = TITLES.home[1];
        closeModal(true);
        render(true);
        win.hidden = false; void win.offsetWidth; win.classList.add('on');
        S.open = true;
        C.play('open');
    }
    function close(notify) {
        if (!S.open) return;
        S.open = false;
        closeModal(true);
        win.classList.remove('on');
        setTimeout(function () { if (!S.open) win.hidden = true; }, 400);
        if (notify) C.api('close', {}).catch(function () {});
    }

    /* ---------- Einladung ---------- */
    var inv = { on: false, t: 0, total: 0, timer: 0, start: 0 };
    function showInvite(d) {
        applyUi(d.ui);
        var el = $('invite');
        $('invFac').textContent = (d.faction && (d.faction.label || d.faction.name)) || d.faction || 'Fraktion';
        $('invText').textContent = d.text || 'Du wurdest eingeladen, der Fraktion beizutreten.';
        $('invRank').textContent = d.grade || '-';
        $('invSalary').textContent = d.salary != null ? money(d.salary) : '-';
        $('invFrom').textContent = d.from || '-';
        el.classList.remove('done');
        $('invYes').lastChild.textContent = 'Annehmen';
        $('invNo').lastChild.textContent = 'Ablehnen';
        inv.total = Math.max(5, Number(d.timeout) || CONFIG.inviteTimeout);
        inv.start = Date.now();
        inv.on = true;
        el.hidden = false; void el.offsetWidth; el.classList.add('on');
        clearInterval(inv.timer);
        tickInvite();
        inv.timer = setInterval(tickInvite, 200);
        C.play('invite');
    }
    function tickInvite() {
        var left = inv.total - (Date.now() - inv.start) / 1000;
        if (left <= 0) { answer(false, true); return; }
        $('invBar').style.transform = 'scaleX(' + Math.max(0, left / inv.total).toFixed(3) + ')';
        $('invLeft').textContent = 'Läuft ab in ' + Math.ceil(left) + ' s';
    }
    function answer(accept, timeout, fromServer) {
        if (!inv.on) return;
        inv.on = false;
        clearInterval(inv.timer);
        var el = $('invite');
        el.classList.add('done');
        $('invLeft').textContent = timeout ? 'Abgelaufen' : accept ? 'Willkommen in der Fraktion' : 'Abgelehnt';
        (accept ? $('invYes') : $('invNo')).style.transform = 'scale(1.04)';
        if (!fromServer) C.api('inviteAnswer', { accept: !!accept, timeout: !!timeout }).catch(function () {});
        C.play(accept ? 'ok' : 'click');
        setTimeout(hideInvite, 900);
    }
    function hideInvite() {
        var el = $('invite');
        inv.on = false; clearInterval(inv.timer);
        el.classList.remove('on');
        $('invYes').style.transform = ''; $('invNo').style.transform = '';
        setTimeout(function () { if (!inv.on) el.hidden = true; }, 450);
    }
    $('invYes').addEventListener('click', function () { answer(true); });
    $('invNo').addEventListener('click', function () { answer(false); });

    /* ---------- Tastatur ---------- */
    window.addEventListener('keydown', function (e) {
        var typing = e.target && (e.target.tagName === 'INPUT' || e.target.tagName === 'SELECT');
        if (inv.on && !typing) {
            if (e.key === 'y' || e.key === 'Y' || e.key === 'z' || e.key === 'Z') { answer(true); return; }
            if (e.key === 'n' || e.key === 'N') { answer(false); return; }
        }
        if (e.key !== 'Escape' || !S.open) return;
        e.preventDefault();
        if ($('modal')) { closeModal(); return; }
        if (S.view !== 'home') { go('home'); return; }
        close(true);
    });

    /* ---------- NUI ---------- */
    window.addEventListener('message', function (e) {
        var d = e.data || {};
        switch (d.action) {
            case 'open': open(d); break;
            case 'update': apply(d); if (S.open) render(false); break;
            case 'close': close(false); break;
            case 'notify': toast(d.text || '', d.type); C.play(d.type === 'error' ? 'error' : 'ok'); break;
            case 'invite': showInvite(d); break;
            case 'inviteKey': answer(!!d.accept, false, true); break;   // Taste im Spiel gedrückt (ohne NUI-Fokus)
            case 'inviteClose': hideInvite(); break;
        }
    });

    /* ---------- Browser-Test ---------- */
    if (C.IS_BROWSER) {
        document.body.classList.add('is-browser');
        var GR = [
            { grade: 0, label: 'Rekrut', salary: 1200 }, { grade: 1, label: 'Officer', salary: 1800 }, { grade: 2, label: 'Sergeant', salary: 2400 },
            { grade: 3, label: 'Lieutenant', salary: 3100 }, { grade: 4, label: 'Captain', salary: 3900 }, { grade: 5, label: 'Chief', salary: 5000 }
        ];
        var MEM = [
            ['Leon Kalt', 5, 1, '01/2026'], ['Carla Benz', 4, 1, '02/2026'], ['Mats Hoffmann', 3, 0, '03/2026'], ['Aylin Demir', 3, 1, '04/2026'],
            ['Jonas Weber', 2, 1, '05/2026'], ['Sofia Klein', 2, 0, '06/2026'], ['Erik Brandt', 1, 1, '08/2026'], ['Nele Wagner', 1, 0, '09/2026'],
            ['Tim Lorenz', 0, 1, '10/2026'], ['Mira Schulz', 0, 0, '10/2026']
        ].map(function (m, i) { return { identifier: 'char1:' + (1000 + i), name: m[0], grade: m[1], online: !!m[2], since: m[3] }; });
        var TX = [
            { type: 'in', note: 'Einzahlung', who: 'Carla Benz', amount: 25000, time: 'Heute, 10:12' },
            { type: 'out', note: 'Gehälter Zahltag', who: 'System', amount: 21600, time: 'Heute, 09:00' },
            { type: 'out', note: 'Auszahlung · Fahrzeugwartung', who: 'Leon Kalt', amount: 8400, time: 'Gestern, 21:40' },
            { type: 'in', note: 'Rechnung bezahlt', who: 'Rechnungssystem', amount: 3200, time: 'Gestern, 18:05' },
            { type: 'in', note: 'Einzahlung', who: 'Aylin Demir', amount: 10000, time: 'Mo, 14:22' }
        ];
        var LOGS = [
            { kind: 'promote', text: 'Jonas Weber zum Sergeant befördert', who: 'Leon Kalt', time: 'vor 8 Min' },
            { kind: 'deposit', text: '$25.000 in die Firmenkasse eingezahlt', who: 'Carla Benz', time: 'vor 42 Min' },
            { kind: 'hire', text: 'Mira Schulz als Rekrut eingestellt', who: 'Carla Benz', time: 'vor 2 Std' },
            { kind: 'settings', text: 'Gehalt für Officer auf $1.800 geändert', who: 'Leon Kalt', time: 'vor 5 Std' },
            { kind: 'withdraw', text: '$8.400 ausgezahlt · Fahrzeugwartung', who: 'Leon Kalt', time: 'Gestern' },
            { kind: 'fire', text: 'Kevin Roth entlassen', who: 'Leon Kalt', time: 'Gestern' },
            { kind: 'demote', text: 'Sofia Klein zum Sergeant zurückgestuft', who: 'Carla Benz', time: 'Mo' }
        ];
        var BAL = 1284500;
        var addLog = function (kind, text) { LOGS = [{ kind: kind, text: text, who: 'Leon Kalt', time: 'gerade eben' }].concat(LOGS); };
        var byId = function (id) { return MEM.filter(function (m) { return m.identifier === id; })[0]; };

        window.__mockApi = function (name, d) {
            if (name === 'promote' || name === 'demote') {
                var m = byId(d.identifier); m.grade = d.grade;
                addLog(name, m.name + (name === 'promote' ? ' zum ' : ' zum ') + GR[d.grade].label + (name === 'promote' ? ' befördert' : ' zurückgestuft'));
                return { ok: true, data: { members: MEM, logs: LOGS } };
            }
            if (name === 'fire') { var f = byId(d.identifier); MEM = MEM.filter(function (x) { return x !== f; }); addLog('fire', f.name + ' entlassen'); return { ok: true, data: { members: MEM, logs: LOGS } }; }
            if (name === 'getNearbyPlayers') return { ok: true, data: [{ id: 14, name: 'Paul Richter' }, { id: 27, name: 'Lea Vogel' }, { id: 31, name: 'Noah Krüger' }] };
            if (name === 'hire') { setTimeout(function () { window.postMessage({ action: 'notify', text: 'Paul Richter hat die Einladung angenommen' }, '*'); }, 2500); return { ok: true }; }
            if (name === 'deposit' || name === 'withdraw') {
                if (name === 'withdraw' && d.amount > BAL) return { ok: false, error: 'So viel ist nicht in der Kasse' };
                BAL += name === 'deposit' ? d.amount : -d.amount;
                TX = [{ type: name === 'deposit' ? 'in' : 'out', note: name === 'deposit' ? 'Einzahlung' : 'Auszahlung', who: 'Leon Kalt', amount: d.amount, time: 'gerade eben' }].concat(TX);
                addLog(name, '$' + d.amount.toLocaleString('de-DE') + (name === 'deposit' ? ' in die Firmenkasse eingezahlt' : ' ausgezahlt'));
                return { ok: true, data: { balance: BAL, transactions: TX, logs: LOGS } };
            }
            if (name === 'saveSettings') { d.grades.forEach(function (g) { GR[g.grade].salary = g.salary; }); addLog('settings', 'Ränge und Einstellungen gespeichert'); return { ok: true, data: { grades: GR, logs: LOGS } }; }
            if (name === 'close') setTimeout(function () { toast('Menü geschlossen (Test)'); }, 0);
            return { ok: true };
        };

        var send = function (m) { window.postMessage(m, '*'); };
        var openMsg = function (perms) {
            return { action: 'open', faction: { name: 'police', label: 'Los Santos Police Department' }, me: 'char1:1000', grades: GR, members: MEM, balance: BAL, weekChange: '+ $38.200 diese Woche', transactions: TX, logs: LOGS, settings: { payFromSociety: true, offDutyPay: false, notifyAll: true }, permissions: perms };
        };
        var bar = document.createElement('div');
        bar.className = 'testbar';
        bar.innerHTML = '<b>Testleiste (nur im Browser)</b>';
        var snd = true;
        [
            ['Bossmenü öffnen', function () { send(openMsg()); }],
            ['Ohne Kasse-Rechte', function () { send(openMsg({ funds: false, settings: false })); }],
            ['Schließen', function () { send({ action: 'close' }); }],
            ['Einladung', function () { send({ action: 'invite', faction: { label: 'Los Santos Police Department' }, grade: 'Rekrut', salary: 1200, from: 'Leon Kalt', timeout: 30 }); }],
            ['Einladung (Y im Spiel)', function () { send({ action: 'inviteKey', accept: true }); }],
            ['Hinweis', function () { send({ action: 'notify', text: 'Zahltag: $21.600 ausgezahlt' }); }],
            ['Ton an/aus', function () { snd = !snd; C.sound(snd); }],
            ['Leiste aus', function () { bar.remove(); }]
        ].forEach(function (x) { var b = document.createElement('button'); b.textContent = x[0]; b.onclick = x[1]; bar.appendChild(b); });
        document.body.appendChild(bar);
        setTimeout(function () { send(openMsg()); }, 200);
    }
})();
