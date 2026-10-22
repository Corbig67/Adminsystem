/* Kleidungsladen · app.js

   NUI-Nachrichten (SendNUIMessage):
     { action = 'open', values = {...}, max = {...}, money = { cash, bank },
       outfits = { { id, name, date, icons } }, prices = { torso = 240, ... },   -- prices optional
       categories = { 'torso', 'pants', ... },                                   -- optional: nur diese zeigen
       title = 'KLEIDUNGSLADEN' }                                                -- optional
     { action = 'setMax',  max = { torso_2 = 5 } }
     { action = 'money',   money = { cash, bank } }
     { action = 'outfits', outfits = {...} }
     { action = 'notify',  text = '...', type = 'success'|'error' }
     { action = 'close' }

   NUI-Callbacks (Antwort: { ok = true, data = ... } oder { ok = false, error = 'Text' }):
     change        { component, values = { torso_1 = 12, torso_2 = 0 } }   -> data = { max = {...} } (optional)
     camera        { mode = 'head'|'body'|'legs'|'feet'|'full' }
     rotate        { dir = -1|1 }
     buy           { method = 'cash'|'bank', total, items = {...}, values = {...}, outfit = 'Name' | nil }
                   -> data = { money = {...}, outfits = {...} } (optional)
     wearOutfit    { id }  -> data = { values = {...}, max = {...} }
     deleteOutfit  { id }  -> data = { outfits = {...} } (optional)
     close         {}      Laden ohne Kauf verlassen: alten Skin wiederherstellen

   values / max nutzen die Keys von skinchanger (esx_skin), z. B. torso_1, torso_2.
   Die Preise werden hier nur angezeigt. Bitte im Backend nachrechnen. */
(function () {
    'use strict';

    var CONFIG = {
        logo: 'img/logo.png',              // eigenes Logo, ohne Datei erscheint ein P
        brand: 'PULSE ROLEPLAY',
        title: 'KLEIDUNGSLADEN',
        currency: '$',
        maxChips: 11,                      // so viele Varianten-Felder auf einmal (eine Reihe)
        categories: [
            { id: 'tshirt',    label: 'T-Shirt', icon: 'shirt',    d: 'tshirt_1',    t: 'tshirt_2',    price: 80,  min: 0 },
            { id: 'torso',     label: 'Oberteil', icon: 'jacket',  d: 'torso_1',     t: 'torso_2',     price: 240, min: 0 },
            { id: 'arms',      label: 'Arme',    icon: 'glove',    d: 'arms',        t: 'arms_2',      price: 60,  min: 0 },
            { id: 'pants',     label: 'Hose',    icon: 'pants',    d: 'pants_1',     t: 'pants_2',     price: 150, min: 0 },
            { id: 'shoes',     label: 'Schuhe',  icon: 'shoes',    d: 'shoes_1',     t: 'shoes_2',     price: 130, min: 0 },
            { id: 'helmet',    label: 'Kopf',    icon: 'cap',      d: 'helmet_1',    t: 'helmet_2',    price: 90,  min: -1 },
            { id: 'glasses',   label: 'Brille',  icon: 'glasses',  d: 'glasses_1',   t: 'glasses_2',   price: 70,  min: 0 },
            { id: 'mask',      label: 'Maske',   icon: 'mask',     d: 'mask_1',      t: 'mask_2',      price: 110, min: 0 },
            { id: 'chain',     label: 'Kette',   icon: 'chain',    d: 'chain_1',     t: 'chain_2',     price: 300, min: 0 },
            { id: 'watches',   label: 'Uhr',     icon: 'watch',    d: 'watches_1',   t: 'watches_2',   price: 260, min: -1 },
            { id: 'bracelets', label: 'Armband', icon: 'bracelet', d: 'bracelets_1', t: 'bracelets_2', price: 90,  min: -1 },
            { id: 'bags',      label: 'Tasche',  icon: 'bag',      d: 'bags_1',      t: 'bags_2',      price: 140, min: 0 }
        ]
    };

    var $ = function (id) { return document.getElementById(id); };
    var app = $('app');

    var S = {
        open: false, tab: 'shop', cat: null, cam: 'body', pay: 'cash', save: false, busy: false,
        cats: [], values: {}, orig: {}, max: {}, prices: {}, money: { cash: 0, bank: 0 }, outfits: []
    };

    function money(n) { return CONFIG.currency + Math.round(n || 0).toLocaleString('de-DE'); }
    function num(v, f) { v = Number(v); return isFinite(v) ? v : f; }
    function catById(id) { for (var i = 0; i < S.cats.length; i++) if (S.cats[i].id === id) return S.cats[i]; return null; }
    function priceOf(c) { return S.prices[c.id] != null ? S.prices[c.id] : c.price; }
    function dOf(c) { return num(S.values[c.d], c.min); }
    function tOf(c) { return num(S.values[c.t], 0); }
    function maxD(c) { return Math.max(c.min, num(S.max[c.d], 0)); }
    function maxT(c) { return Math.max(0, num(S.max[c.t], 0)); }
    function changed(c) { return dOf(c) !== num(S.orig[c.d], c.min) || tOf(c) !== num(S.orig[c.t], 0); }

    /* ---------- Logo ---------- */
    (function () {
        var l = $('logo');
        $('brandName').textContent = CONFIG.brand;
        if (!CONFIG.logo) { l.classList.add('fb'); return; }
        var im = new Image();
        im.alt = '';
        im.onload = function () { l.classList.remove('fb'); l.insertBefore(im, l.firstChild); };
        im.onerror = function () { l.classList.add('fb'); };
        l.classList.add('fb');
        im.src = CONFIG.logo;
    })();

    /* ---------- Hinweise ---------- */
    function toast(text, type) {
        var box = $('toasts');
        var el = document.createElement('div');
        el.className = 'toast ' + (type || 'success');
        var ic = type === 'error'
            ? '<path d="M12 7v6M12 17v.01"/>'
            : '<path d="M5 12.5l4.5 4.5L19 7.5"/>';
        el.innerHTML = '<span class="t-ic"><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="3" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">' + ic + '</svg></span><span>' + C.esc(text) + '</span>';
        box.appendChild(el);
        while (box.children.length > 3) box.firstChild.remove();
        setTimeout(function () { el.classList.add('out'); setTimeout(function () { el.remove(); }, 300); }, 3200);
    }

    /* ---------- Segment-Markierung ---------- */
    function moveHl(segId, hlId, attr, val, step) {
        var btns = $(segId).querySelectorAll('button[' + attr + ']');
        for (var i = 0; i < btns.length; i++) {
            var on = btns[i].getAttribute(attr) === val;
            btns[i].classList.toggle('on', on);
            if (on) $(hlId).style.transform = 'translateX(' + (i * step) + 'px)';
        }
    }

    /* ---------- Kacheln ---------- */
    function renderTiles() {
        $('tiles').innerHTML = S.cats.map(function (c, i) {
            return '<button type="button" class="tile' + (c.id === S.cat ? ' on' : '') + (changed(c) ? ' changed' : '') + '" data-cat="' + c.id + '" style="--i:' + i + '">' +
                '<svg width="42" height="42" viewBox="0 0 64 64" aria-hidden="true"><use href="#i-' + c.icon + '"/></svg>' +
                '<span>' + C.esc(c.label) + '</span><i class="dot"></i></button>';
        }).join('');
    }
    function refreshTiles() {
        var tiles = $('tiles').children;
        for (var i = 0; i < tiles.length; i++) {
            var c = catById(tiles[i].getAttribute('data-cat'));
            tiles[i].classList.toggle('on', c.id === S.cat);
            tiles[i].classList.toggle('changed', changed(c));
        }
    }

    /* ---------- Editor ---------- */
    function renderEditor(swap) {
        var c = catById(S.cat); if (!c) return;
        var d = dOf(c), t = tOf(c), mD = maxD(c), mT = maxT(c);
        if (swap) {
            var h = document.querySelector('.ed-head');
            h.classList.remove('swap'); void h.offsetWidth; h.classList.add('swap');
        }
        $('edIcon').setAttribute('href', '#i-' + c.icon);
        $('edName').textContent = c.label.toUpperCase();
        $('edPrice').textContent = money(priceOf(c));
        $('dNum').textContent = d;
        $('dMax').textContent = mD;
        var r = $('mdl');
        r.min = c.min; r.max = mD; r.value = d;
        r.style.setProperty('--p', (mD > c.min ? ((d - c.min) / (mD - c.min)) * 100 : 0).toFixed(1) + '%');
        $('tNum').textContent = t + 1;
        $('tMax').textContent = mT + 1;

        // Varianten-Felder (bei vielen Varianten ein Ausschnitt mit Blättern)
        var total = mT + 1, html = '';
        var n = CONFIG.maxChips;
        if (total <= n) {
            for (var k = 0; k < total; k++) html += chip(k, t);
        } else {
            var span = n - 2;
            var start = Math.max(0, Math.min(t - Math.floor(span / 2), total - span));
            html += '<button type="button" class="chip nav" data-tnav="-1" aria-label="Vorherige Varianten"' + (start === 0 ? ' disabled' : '') + '>‹</button>';
            for (var j = start; j < start + span; j++) html += chip(j, t);
            html += '<button type="button" class="chip nav" data-tnav="1" aria-label="Weitere Varianten"' + (start + span >= total ? ' disabled' : '') + '>›</button>';
        }
        $('chips').innerHTML = html;

        var ch = changed(c);
        $('edState').textContent = ch ? 'Geändert · liegt im Warenkorb' : 'Das trägst du gerade';
        $('btnRevert').disabled = !ch;
    }
    function chip(k, t) {
        return '<button type="button" class="chip' + (k === t ? ' on' : '') + '" data-t="' + k + '" aria-label="Variante ' + (k + 1) + '">' + (k + 1) + '</button>';
    }

    /* ---------- Änderungen an den Server (gedrosselt) ---------- */
    var pending = {}, timers = {};
    function sendChange(c) {
        pending[c.id] = true;
        if (timers[c.id]) return;
        timers[c.id] = setTimeout(function flush() {
            timers[c.id] = null;
            if (!pending[c.id]) return;
            pending[c.id] = false;
            var vals = {}; vals[c.d] = dOf(c); vals[c.t] = tOf(c);
            C.api('change', { component: c.id, values: vals }).then(function (r) {
                if (r && r.max) applyMax(r.max);
            }).catch(function () {});
        }, 50);
    }
    function applyMax(m) {
        for (var k in m) if (Object.prototype.hasOwnProperty.call(m, k)) S.max[k] = num(m[k], 0);
        // Variante begrenzen, falls das neue Modell weniger hat
        S.cats.forEach(function (c) { if (tOf(c) > maxT(c)) { S.values[c.t] = maxT(c); } });
        renderEditor(false);
    }

    function setPart(c, d, t, sound) {
        var oldD = dOf(c);
        S.values[c.d] = d;
        S.values[c.t] = t;
        if (d !== oldD) { var n = $('dNum'); n.classList.remove('bump'); void n.offsetWidth; n.classList.add('bump'); }
        renderEditor(false);
        refreshTiles();
        renderCart();
        sendChange(c);
        if (sound !== false) C.play('tick');
    }
    function stepD(dir) {
        var c = catById(S.cat); if (!c) return;
        var d = dOf(c) + dir, mD = maxD(c);
        if (d > mD) d = c.min;
        if (d < c.min) d = mD;
        setPart(c, d, 0);
    }
    function stepT(dir) {
        var c = catById(S.cat); if (!c) return;
        var t = tOf(c) + dir, mT = maxT(c);
        if (t > mT) t = 0;
        if (t < 0) t = mT;
        setPart(c, dOf(c), t);
    }
    function stepCat(dir) {
        if (!S.cats.length) return;
        var i = 0;
        while (i < S.cats.length && S.cats[i].id !== S.cat) i++;
        i = (i + dir + S.cats.length) % S.cats.length;
        S.cat = S.cats[i].id; refreshTiles(); renderEditor(true); C.play('click');
    }

    /* ---------- Warenkorb ---------- */
    function cartItems() {
        return S.cats.filter(changed).map(function (c) {
            return { id: c.id, label: c.label, icon: c.icon, price: priceOf(c), d: dOf(c), t: tOf(c), keys: [c.d, c.t] };
        });
    }
    function cartTotal(items) { return items.reduce(function (a, i) { return a + i.price; }, 0); }

    function renderCart() {
        var items = cartItems(), list = $('cartList');
        var want = {};
        items.forEach(function (i) { want[i.id] = i; });

        // entfernen (mit Animation)
        Array.prototype.slice.call(list.querySelectorAll('.ci')).forEach(function (el) {
            var id = el.getAttribute('data-id');
            if (!want[id] && !el.classList.contains('out')) {
                el.classList.add('out');
                setTimeout(function () { el.remove(); }, 260);
            }
        });
        // hinzufügen / aktualisieren
        items.forEach(function (i) {
            var el = list.querySelector('.ci[data-id="' + i.id + '"]:not(.out)');
            var sub = 'Modell ' + i.d + ' · Variante ' + (i.t + 1);
            if (!el) {
                el = document.createElement('div');
                el.className = 'ci'; el.setAttribute('data-id', i.id);
                el.innerHTML = '<svg width="34" height="34" viewBox="0 0 64 64" aria-hidden="true"><use href="#i-' + i.icon + '"/></svg>' +
                    '<span class="ci-txt"><b>' + C.esc(i.label) + '</b><span class="ci-sub"></span></span>' +
                    '<span class="ci-p">' + money(i.price) + '</span>' +
                    '<button type="button" class="x" data-rm="' + i.id + '" aria-label="' + C.esc(i.label) + ' entfernen"><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" aria-hidden="true"><path d="M6 6l12 12M18 6L6 18"/></svg></button>';
                list.appendChild(el);
            }
            el.querySelector('.ci-sub').textContent = sub;
        });

        var empty = list.querySelector('.empty');
        if (!items.length && !empty) {
            empty = document.createElement('p');
            empty.className = 'empty'; empty.textContent = 'Noch nichts ausgewählt. Probier links ein Teil an.';
            list.appendChild(empty);
        } else if (items.length && empty) empty.remove();

        $('cartCount').textContent = items.length === 1 ? '1 Teil' : items.length + ' Teile';
        var tot = $('total'), txt = money(cartTotal(items));
        if (tot.textContent !== txt) { tot.textContent = txt; tot.classList.remove('bump'); void tot.offsetWidth; tot.classList.add('bump'); }
        renderPay();
    }

    function renderPay() {
        var items = cartItems(), sum = cartTotal(items);
        $('cash').textContent = money(S.money.cash);
        $('bank').textContent = money(S.money.bank);
        var pms = document.querySelectorAll('.pm');
        for (var i = 0; i < pms.length; i++) {
            var m = pms[i].getAttribute('data-pay');
            pms[i].classList.toggle('on', m === S.pay);
            pms[i].classList.toggle('low', sum > 0 && sum > (S.money[m] || 0));
        }
        var wallet = S.money[S.pay] || 0;
        var name = $('outfitName').value.trim();
        var err = '';
        if (items.length && sum > wallet) err = S.pay === 'cash' ? 'Nicht genug Bargeld' : 'Nicht genug Guthaben';
        else if (items.length && S.save && !name) err = 'Gib deinem Outfit einen Namen';
        $('payErr').textContent = err || ' ';
        $('payErr').classList.toggle('on', !!err);
        $('outfitName').classList.toggle('need', !!(items.length && S.save && !name));

        var b = $('btnBuy');
        b.disabled = S.busy || !items.length || !!err;
        $('buySmall').textContent = items.length ? money(sum) + ' · ' + (S.pay === 'cash' ? 'Bar' : 'Karte') : 'Warenkorb leer';
    }

    /* ---------- Outfits ---------- */
    function renderOutfits() {
        $('outfitCount').textContent = S.outfits.length;
        var box = $('outfits');
        if (!S.outfits.length) { box.innerHTML = '<p class="empty">Noch keine Outfits gespeichert.</p>'; return; }
        box.innerHTML = S.outfits.map(function (o, i) {
            var ics = (o.icons && o.icons.length ? o.icons : ['jacket', 'pants', 'shoes']).slice(0, 3);
            return '<div class="of" data-of="' + C.esc(o.id) + '" style="--i:' + i + '">' +
                '<span class="of-ics">' + ics.map(function (n) { return '<svg width="26" height="26" viewBox="0 0 64 64" aria-hidden="true"><use href="#i-' + C.esc(n) + '"/></svg>'; }).join('') + '</span>' +
                '<span class="of-txt"><b>' + C.esc(o.name) + '</b><span>' + (o.date ? 'Gespeichert am ' + C.esc(o.date) : '') + '</span></span>' +
                '<button type="button" class="wear" data-wear="' + C.esc(o.id) + '">Anziehen</button>' +
                '<button type="button" class="x" data-del="' + C.esc(o.id) + '" aria-label="Outfit löschen"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M4 7h16M10 11v6M14 11v6M6 7l1 13h10l1-13M9 7V4h6v3"/></svg></button></div>';
        }).join('');
    }

    function setTab(tab) {
        if (S.tab === tab) return;
        S.tab = tab;
        moveHl('tabs', 'tabHl', 'data-tab', tab, 172);
        $('viewShop').hidden = tab !== 'shop';
        $('viewOutfits').hidden = tab !== 'outfits';
        C.play('click');
    }

    /* ---------- Öffnen / Schließen ---------- */
    function open(d) {
        S.values = Object.assign({}, d.values || {});
        S.orig = Object.assign({}, S.values);
        S.max = Object.assign({}, d.max || {});
        S.prices = d.prices || {};
        S.money = { cash: num(d.money && d.money.cash, 0), bank: num(d.money && d.money.bank, 0) };
        S.outfits = d.outfits || [];
        S.cats = Array.isArray(d.categories) && d.categories.length
            ? CONFIG.categories.filter(function (c) { return d.categories.indexOf(c.id) !== -1; })
            : CONFIG.categories.slice();
        S.cat = S.cats.length ? S.cats[Math.min(1, S.cats.length - 1)].id : null;
        S.tab = 'shop'; moveHl('tabs', 'tabHl', 'data-tab', 'shop', 172);
        $('viewShop').hidden = false; $('viewOutfits').hidden = true;
        S.pay = d.pay === 'bank' ? 'bank' : 'cash';
        S.save = false; $('saveChk').checked = false; $('saveIn').classList.remove('on'); $('outfitName').value = '';
        S.busy = false; $('btnBuy').classList.remove('busy');
        S.cam = 'body'; moveHl('camSeg', 'camHl', 'data-cam', 'body', 108);
        $('shopTitle').textContent = d.title || CONFIG.title;

        $('cartList').innerHTML = '';
        renderTiles(); renderEditor(false); renderCart(); renderOutfits();

        app.classList.remove('hidden');
        void app.offsetWidth;
        app.classList.add('open');
        S.open = true;
        C.play('open');
    }

    function hide() {
        S.open = false;
        app.classList.remove('open');
        setTimeout(function () { if (!S.open) app.classList.add('hidden'); }, 450);
    }

    function leave() {
        if (!S.open) return;
        hide();
        C.api('close', {}).catch(function () {});
    }

    /* ---------- Kaufen ---------- */
    function buy() {
        var items = cartItems(); if (!items.length || S.busy) return;
        var name = $('outfitName').value.trim();
        var payload = {
            method: S.pay,
            total: cartTotal(items),
            items: items.map(function (i) {
                var v = {}; v[i.keys[0]] = i.d; v[i.keys[1]] = i.t;
                return { component: i.id, label: i.label, price: i.price, values: v };
            }),
            values: Object.assign({}, S.values),
            outfit: S.save && name ? name : null
        };
        S.busy = true; $('btnBuy').classList.add('busy'); renderPay();
        C.api('buy', payload).then(function (r) {
            S.orig = Object.assign({}, S.values);
            if (r && r.money) S.money = { cash: num(r.money.cash, S.money.cash), bank: num(r.money.bank, S.money.bank) };
            else S.money[S.pay] = (S.money[S.pay] || 0) - payload.total;
            if (r && r.outfits) { S.outfits = r.outfits; renderOutfits(); }
            toast('Gekauft für ' + money(payload.total) + (payload.outfit ? ' · Outfit „' + payload.outfit + '“ gespeichert' : ''));
            C.play('buy');
            $('outfitName').value = '';
            if (payload.outfit) { S.save = false; $('saveChk').checked = false; $('saveIn').classList.remove('on'); }
        }).catch(function (e) {
            toast(e.message, 'error'); C.play('error');
        }).then(function () {
            S.busy = false; $('btnBuy').classList.remove('busy');
            refreshTiles(); renderEditor(false); renderCart();
        });
    }

    /* ---------- Ereignisse ---------- */
    $('tiles').addEventListener('click', function (e) {
        var b = e.target.closest('.tile'); if (!b) return;
        var id = b.getAttribute('data-cat');
        if (id === S.cat) return;
        S.cat = id; refreshTiles(); renderEditor(true); C.play('click');
    });
    document.querySelectorAll('.arr').forEach(function (b) {
        b.addEventListener('click', function () { stepD(+b.getAttribute('data-step')); });
    });
    $('mdl').addEventListener('input', function () {
        var c = catById(S.cat); if (!c) return;
        var d = +this.value;
        if (d !== dOf(c)) setPart(c, d, 0, false);
    });
    $('mdl').addEventListener('change', function () { C.play('tick'); });
    $('chips').addEventListener('click', function (e) {
        var b = e.target.closest('.chip'); if (!b || b.disabled) return;
        var c = catById(S.cat); if (!c) return;
        if (b.hasAttribute('data-tnav')) {
            var t = Math.max(0, Math.min(maxT(c), tOf(c) + (+b.getAttribute('data-tnav')) * (CONFIG.maxChips - 2)));
            setPart(c, dOf(c), t);
            return;
        }
        var k = +b.getAttribute('data-t');
        if (k !== tOf(c)) setPart(c, dOf(c), k);
    });
    $('btnRevert').addEventListener('click', function () {
        var c = catById(S.cat); if (!c) return;
        setPart(c, num(S.orig[c.d], c.min), num(S.orig[c.t], 0));
    });
    $('cartList').addEventListener('click', function (e) {
        var b = e.target.closest('[data-rm]'); if (!b) return;
        var c = catById(b.getAttribute('data-rm')); if (!c) return;
        setPart(c, num(S.orig[c.d], c.min), num(S.orig[c.t], 0));
        C.play('click');
    });

    $('tabs').addEventListener('click', function (e) {
        var b = e.target.closest('button[data-tab]'); if (b) setTab(b.getAttribute('data-tab'));
    });
    $('camSeg').addEventListener('click', function (e) {
        var b = e.target.closest('button[data-cam]'); if (!b) return;
        var m = b.getAttribute('data-cam'); if (m === S.cam) return;
        S.cam = m; moveHl('camSeg', 'camHl', 'data-cam', m, 108);
        C.api('camera', { mode: m }).catch(function () {});
        C.play('click');
    });
    document.querySelectorAll('[data-rot]').forEach(function (b) {
        b.addEventListener('click', function () { C.api('rotate', { dir: +b.getAttribute('data-rot') }).catch(function () {}); });
    });

    document.querySelectorAll('.pm').forEach(function (b) {
        b.addEventListener('click', function () { S.pay = b.getAttribute('data-pay'); renderPay(); C.play('click'); });
    });
    $('saveChk').addEventListener('change', function () {
        S.save = this.checked;
        $('saveIn').classList.toggle('on', S.save);
        if (S.save) setTimeout(function () { $('outfitName').focus(); }, 30);
        renderPay(); C.play('click');
    });
    $('outfitName').addEventListener('input', renderPay);
    $('outfitName').addEventListener('keydown', function (e) { if (e.key === 'Enter') { e.preventDefault(); buy(); } });
    $('btnBuy').addEventListener('click', buy);

    $('outfits').addEventListener('click', function (e) {
        var w = e.target.closest('[data-wear]'), d = e.target.closest('[data-del]');
        if (w) {
            var id = w.getAttribute('data-wear');
            C.api('wearOutfit', { id: id }).then(function (r) {
                if (r && r.values) { Object.assign(S.values, r.values); S.orig = Object.assign({}, S.values); }
                if (r && r.max) Object.assign(S.max, r.max);
                refreshTiles(); renderEditor(false); renderCart();
                var o = S.outfits.filter(function (x) { return String(x.id) === id; })[0];
                toast('Outfit „' + (o ? o.name : '') + '“ angezogen'); C.play('ok');
            }).catch(function (er) { toast(er.message, 'error'); C.play('error'); });
        } else if (d) {
            var did = d.getAttribute('data-del');
            var row = d.closest('.of');
            C.api('deleteOutfit', { id: did }).then(function (r) {
                row.classList.add('out');
                setTimeout(function () {
                    S.outfits = r && r.outfits ? r.outfits : S.outfits.filter(function (x) { return String(x.id) !== did; });
                    renderOutfits();
                }, 280);
                C.play('click');
            }).catch(function (er) { toast(er.message, 'error'); C.play('error'); });
        }
    });

    // Tastatur: A/D drehen, Q/E Teil, Pfeile links/rechts Modell, hoch/runter Variante, ESC verlassen
    var lastRot = 0;
    window.addEventListener('keydown', function (e) {
        if (!S.open) return;
        if (e.key === 'Escape') { e.preventDefault(); leave(); return; }
        if (e.target && e.target.tagName === 'INPUT' && e.target.type === 'text') return;
        var k = e.key.toLowerCase();
        if (k === 'a' || k === 'd') {
            var now = Date.now(); if (now - lastRot < 70) return; lastRot = now;
            C.api('rotate', { dir: k === 'a' ? -1 : 1 }).catch(function () {});
            return;
        }
        if (S.tab !== 'shop') return;
        if (k === 'q' || k === 'e') {
            e.preventDefault(); stepCat(k === 'q' ? -1 : 1);
        } else if (e.key === 'ArrowLeft' || e.key === 'ArrowRight') {
            if (e.target && e.target.type === 'range') return; // Regler regelt selbst
            e.preventDefault(); stepD(e.key === 'ArrowLeft' ? -1 : 1);
        } else if (e.key === 'ArrowUp' || e.key === 'ArrowDown') {
            e.preventDefault(); stepT(e.key === 'ArrowUp' ? 1 : -1);
        }
    });

    /* ---------- NUI ---------- */
    window.addEventListener('message', function (e) {
        var d = e.data || {};
        switch (d.action) {
            case 'open': open(d); break;
            case 'close': hide(); break;
            case 'setMax': if (d.max) applyMax(d.max); break;
            case 'money': if (d.money) { S.money = { cash: num(d.money.cash, S.money.cash), bank: num(d.money.bank, S.money.bank) }; renderPay(); } break;
            case 'outfits': S.outfits = d.outfits || []; renderOutfits(); break;
            case 'notify': toast(d.text || '', d.type); C.play(d.type === 'error' ? 'error' : 'ok'); break;
        }
    });

    /* ---------- Browser-Test ---------- */
    if (C.IS_BROWSER) {
        document.body.classList.add('is-browser');
        var stage = document.querySelector('.stage');
        var ped = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
        ped.setAttribute('class', 'ped-ph'); ped.setAttribute('viewBox', '0 0 300 720'); ped.setAttribute('aria-hidden', 'true');
        ped.innerHTML = '<circle cx="150" cy="80" r="52" fill="#15171B"/><path d="M70 180c10-30 40-46 80-46s70 16 80 46l20 190c2 18-22 22-26 4l-18-150-6 120 10 310c1 20-36 22-38 2l-22-290-22 290c-2 20-39 18-38-2l10-310-6-120-18 150c-4 18-28 14-26-4z" fill="#15171B"/>';
        stage.insertBefore(ped, stage.firstChild);

        var VALS = { tshirt_1: 15, tshirt_2: 0, torso_1: 4, torso_2: 2, arms: 0, arms_2: 0, pants_1: 24, pants_2: 1, shoes_1: 7, shoes_2: 0, helmet_1: -1, helmet_2: 0, glasses_1: 0, glasses_2: 0, mask_1: 0, mask_2: 0, chain_1: 0, chain_2: 0, watches_1: -1, watches_2: 0, bracelets_1: -1, bracelets_2: 0, bags_1: 0, bags_2: 0 };
        var MAX = { tshirt_1: 188, tshirt_2: 7, torso_1: 420, torso_2: 11, arms: 196, arms_2: 3, pants_1: 160, pants_2: 9, shoes_1: 120, shoes_2: 15, helmet_1: 180, helmet_2: 7, glasses_1: 40, glasses_2: 9, mask_1: 220, mask_2: 5, chain_1: 150, chain_2: 3, watches_1: 40, watches_2: 5, bracelets_1: 20, bracelets_2: 3, bags_1: 90, bags_2: 23 };
        var OUTFITS = [
            { id: 1, name: 'Alltag', date: '14.10.2026', icons: ['jacket', 'pants', 'shoes'] },
            { id: 2, name: 'Arbeit', date: '02.10.2026', icons: ['shirt', 'pants', 'watch'] }
        ];
        var nextId = 3, MONEY = { cash: 2450, bank: 18900 };

        window.__mockApi = function (name, data) {
            if (name === 'change') {
                var k = Object.keys(data.values)[0], d = data.values[k], tk = Object.keys(data.values)[1];
                var m = {}; m[tk] = Math.abs(d * 7) % 13 + 1;
                return { ok: true, data: { max: m } };
            }
            if (name === 'buy') {
                if ((MONEY[data.method] || 0) < data.total) return { ok: false, error: data.method === 'cash' ? 'Du hast nicht genug Bargeld dabei' : 'Deine Karte wurde abgelehnt' };
                MONEY[data.method] -= data.total;
                var r = { money: MONEY };
                if (data.outfit) {
                    var ic = data.items.map(function (i) { return catById(i.component).icon; }).concat(['shirt', 'pants', 'shoes']).slice(0, 3);
                    OUTFITS = [{ id: nextId++, name: data.outfit, date: new Date().toLocaleDateString('de-DE'), icons: ic }].concat(OUTFITS);
                    r.outfits = OUTFITS;
                }
                return { ok: true, data: r };
            }
            if (name === 'wearOutfit') return { ok: true, data: { values: { torso_1: 11 + (+data.id) * 3, torso_2: 0, pants_1: 4, pants_2: 2 } } };
            if (name === 'deleteOutfit') { OUTFITS = OUTFITS.filter(function (o) { return String(o.id) !== String(data.id); }); return { ok: true, data: { outfits: OUTFITS } }; }
            if (name === 'close') setTimeout(function () { toast('Laden verlassen (Test)'); }, 0);
            return { ok: true };
        };

        var send = function (m) { window.postMessage(m, '*'); };
        var openMsg = function (cash, bank) {
            MONEY = { cash: cash, bank: bank };
            return { action: 'open', values: VALS, max: MAX, money: MONEY, outfits: OUTFITS };
        };
        var bar = document.createElement('div');
        bar.className = 'testbar';
        bar.innerHTML = '<b>Testleiste (nur im Browser)</b>';
        var soundOn = true;
        [
            ['Öffnen', function () { send(openMsg(2450, 18900)); }],
            ['Öffnen (wenig Geld)', function () { send(openMsg(120, 300)); }],
            ['Nur Kopf + Brille', function () { var m = openMsg(2450, 18900); m.categories = ['helmet', 'glasses', 'mask']; m.title = 'HUTLADEN'; send(m); }],
            ['Hinweis', function () { send({ action: 'notify', text: 'Lieferung ist angekommen' }); }],
            ['Schließen', function () { send({ action: 'close' }); }],
            ['Ton an/aus', function () { soundOn = !soundOn; C.sound(soundOn); }],
            ['Leiste aus', function () { bar.remove(); }]
        ].forEach(function (x) { var b = document.createElement('button'); b.textContent = x[0]; b.onclick = x[1]; bar.appendChild(b); });
        document.body.appendChild(bar);
        setTimeout(function () { send(openMsg(2450, 18900)); }, 200);
    }
})();
