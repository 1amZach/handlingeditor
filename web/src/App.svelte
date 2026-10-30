<script lang="ts">
    import FieldRow from './lib/FieldRow.svelte';
    import Telemetry from './lib/Telemetry.svelte';
    import { inGame, onMessage, post } from './lib/nui';
    import { same, toMeta } from './lib/meta';
    import type { Field, OpenData, Preset, Telemetry as Tele, Value, Values } from './lib/types';

    let visible = $state(false);
    let driving = $state(false);
    let fields = $state<Field[]>([]);
    let vehicle = $state({ label: '', model: '' });
    let stock = $state<Values>({});
    let values = $state<Values>({});
    let presets = $state<Record<string, Preset>>({});
    let tele = $state<Tele | null>(null);
    let launch = $state<{ time: number; best: number } | null>(null);
    let group = $state('All');
    let search = $state('');
    let showChanged = $state(false);
    let presetName = $state('');
    let presetsOpen = $state(false);

    // undo/redo keep whole snapshots, they're small
    let undo = $state<Values[]>([]);
    let redo = $state<Values[]>([]);

    const groups = $derived(['All', ...new Set(fields.map((f) => f.group))]);
    const changedCount = $derived(fields.filter((f) => values[f.name] !== undefined && !same(values[f.name], stock[f.name])).length);

    const shown = $derived(
        fields.filter((f) => {
            if (group !== 'All' && f.group !== group) return false;
            if (showChanged && same(values[f.name], stock[f.name])) return false;
            const q = search.trim().toLowerCase();
            return !q || f.label.toLowerCase().includes(q) || f.name.toLowerCase().includes(q);
        }),
    );

    // lua sends {} for an empty table and [] can't hold names, so normalise
    function asPresets(raw: OpenData['presets'] | undefined): Record<string, Preset> {
        return raw && !Array.isArray(raw) ? raw : {};
    }

    // JSON copy rather than structuredClone, FiveM's browser can be older than desktop Chrome
    const clone = <T,>(v: T): T => JSON.parse(JSON.stringify(v));
    const snapshot = () => clone($state.snapshot(values)) as Values;

    // slider drags send at most every 50ms, the final value always goes through
    let queued: Values = {};
    let timer: number | undefined;
    function push(changes: Values, now = false) {
        Object.assign(queued, changes);
        if (now) {
            clearTimeout(timer);
            timer = undefined;
            flush();
        } else if (timer === undefined) {
            timer = window.setTimeout(() => { timer = undefined; flush(); }, 50);
        }
    }
    function flush() {
        if (Object.keys(queued).length === 0) return;
        post('set', { values: queued });
        queued = {};
    }

    let dragStart: Values | null = null;

    function change(name: string, value: Value, commit: boolean) {
        if (!commit) {
            dragStart ??= snapshot();
        } else {
            undo = [...undo.slice(-99), dragStart ?? snapshot()];
            redo = [];
            dragStart = null;
        }
        values[name] = value;
        push({ [name]: value }, commit);
    }

    function setAll(next: Values, record = true) {
        if (record) {
            undo = [...undo.slice(-99), snapshot()];
            redo = [];
        }
        values = clone(next);
        push(next, true);
    }

    function doUndo() {
        const prev = undo[undo.length - 1];
        if (!prev) return;
        redo = [...redo, snapshot()];
        undo = undo.slice(0, -1);
        setAll(prev, false);
    }

    function doRedo() {
        const next = redo[redo.length - 1];
        if (!next) return;
        undo = [...undo, snapshot()];
        redo = redo.slice(0, -1);
        setAll(next, false);
    }

    function resetAll() {
        undo = [...undo.slice(-99), snapshot()];
        redo = [];
        values = clone($state.snapshot(stock)) as Values;
        post('reset');
    }

    async function savePreset() {
        const name = presetName.trim();
        if (!name) return;
        presets = asPresets(await post('savePreset', { name, values: snapshot() })) || presets;
        if (!inGame) presets = { ...presets, [name]: { model: vehicle.model, values: snapshot() } };
        presetName = '';
    }

    async function deletePreset(name: string) {
        presets = asPresets(await post('deletePreset', { name }));
        if (!inGame) { const { [name]: _, ...rest } = presets; presets = rest; }
    }

    function loadPreset(preset: Preset) {
        setAll({ ...snapshot(), ...preset.values });
        presetsOpen = false;
    }

    function exportMeta() {
        post('copy', { text: toMeta(vehicle.model, fields, snapshot()) });
    }

    function close() {
        post('close');
        visible = false;
    }

    onMessage((action, data) => {
        if (action === 'open') {
            const d = data as OpenData;
            fields = d.fields;
            vehicle = d.vehicle;
            stock = d.stock;
            values = d.values;
            presets = asPresets(d.presets);
            undo = [];
            redo = [];
            launch = null;
            tele = null;
            visible = true;
            driving = false;
        } else if (action === 'mode') {
            driving = data.driving;
        } else if (action === 'telemetry') {
            tele = data;
        } else if (action === 'launch') {
            launch = data;
        } else if (action === 'close') {
            visible = false;
        }
    });

    function onkeydown(e: KeyboardEvent) {
        if (!visible || driving) return;
        const typing = (e.target as HTMLElement)?.tagName === 'INPUT';

        if (e.key === 'Escape') {
            e.preventDefault();
            post('drive');
        } else if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 'z' && !typing) {
            e.preventDefault();
            e.shiftKey ? doRedo() : doUndo();
        } else if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 'y' && !typing) {
            e.preventDefault();
            doRedo();
        }
    }

    // fake data so the page can be styled in a normal browser
    if (!inGame) {
        import('./lib/mock').then((m) => window.postMessage({ action: 'open', data: m.mock }, '*'));
    }
</script>

<svelte:window {onkeydown} />

{#if visible && driving}
    <div class="driving">
        <Telemetry data={tele} {launch} compact />
        <p>Driving. Use the handling key or command again to keep editing.</p>
    </div>
{:else if visible}
    <aside class="panel">
        <header>
            <div class="title">
                <span class="eyebrow">Handling</span>
                <h1>{vehicle.label}</h1>
                <span class="model">{vehicle.model}</span>
            </div>
            <div class="actions">
                <button class="primary" onclick={() => post('drive')} title="Esc">Test drive</button>
                <button class="icon" onclick={close} title="Close">✕</button>
            </div>
        </header>

        <Telemetry data={tele} {launch} />

        <nav class="groups">
            {#each groups as g}
                <button class:active={group === g} onclick={() => (group = g)}>{g}</button>
            {/each}
        </nav>

        <div class="filters">
            <input class="search" placeholder="Search fields" bind:value={search} />
            <label class="toggle">
                <input type="checkbox" bind:checked={showChanged} />
                Changed <span class="count">{changedCount}</span>
            </label>
        </div>

        <div class="list">
            {#each shown as field (field.name)}
                {#if group === 'All' && field.group !== shown[shown.indexOf(field) - 1]?.group}
                    <h2>{field.group}</h2>
                {/if}
                <FieldRow
                    {field}
                    value={values[field.name]!}
                    stock={stock[field.name]!}
                    onchange={(v, commit) => change(field.name, v, commit)}
                />
            {:else}
                <p class="empty">{showChanged ? 'Nothing changed yet.' : 'No fields match.'}</p>
            {/each}
        </div>

        {#if presetsOpen}
            <div class="presets">
                <div class="save">
                    <input placeholder="Preset name" bind:value={presetName} maxlength="40"
                        onkeydown={(e) => e.key === 'Enter' && savePreset()} />
                    <button class="primary" onclick={savePreset} disabled={!presetName.trim()}>Save</button>
                </div>
                {#each Object.entries(presets) as [name, preset] (name)}
                    <div class="preset">
                        <button class="load" onclick={() => loadPreset(preset)}>
                            {name}
                            {#if preset.model}<span>{preset.model}</span>{/if}
                        </button>
                        <button class="icon" title="Delete" onclick={() => deletePreset(name)}>✕</button>
                    </div>
                {:else}
                    <p class="empty">No presets yet.</p>
                {/each}
            </div>
        {/if}

        <footer>
            <button onclick={doUndo} disabled={undo.length === 0} title="Ctrl+Z">Undo</button>
            <button onclick={doRedo} disabled={redo.length === 0} title="Ctrl+Y">Redo</button>
            <button onclick={resetAll} disabled={changedCount === 0} title="Put every field back to stock">Reset</button>
            <span class="spacer"></span>
            <button class:active={presetsOpen} onclick={() => (presetsOpen = !presetsOpen)}>Presets</button>
            <button class="primary" onclick={exportMeta} title="Copy as handling.meta XML">Export</button>
        </footer>
    </aside>
{/if}

<style>
    :global(:root) {
        --bg: rgba(11, 9, 24, 0.94);
        --panel-2: rgba(19, 15, 40, 0.9);
        --hover: rgba(255, 255, 255, 0.03);
        --line: rgba(156, 44, 241, 0.22);
        --track: rgba(255, 255, 255, 0.1);
        --input: rgba(255, 255, 255, 0.05);
        --text: #e9e4f5;
        --muted: #8f86b8;
        --violet: #9c2cf1;
        --teal: #2bd9cc;
        --teal-dim: rgba(43, 217, 204, 0.25);
        --sans: 'Segoe UI', 'Helvetica Neue', Arial, sans-serif;
        --mono: 'Cascadia Mono', Consolas, 'Courier New', monospace;
    }
    :global(html), :global(body) {
        margin: 0; height: 100%; background: transparent; overflow: hidden;
        font-family: var(--sans); color: var(--text); user-select: none;
    }
    :global(button) { font: inherit; }

    .panel {
        position: fixed; top: 24px; right: 24px; bottom: 24px; width: 440px;
        display: flex; flex-direction: column;
        background: var(--bg); border: 1px solid var(--line); border-radius: 14px;
        box-shadow: 0 20px 60px rgba(0, 0, 0, 0.55); overflow: hidden;
        animation: slide 0.2s ease-out;
    }
    @keyframes slide { from { transform: translateX(24px); opacity: 0; } }

    header { display: flex; align-items: flex-start; justify-content: space-between; padding: 16px 16px 12px; }
    .eyebrow { font-size: 10px; letter-spacing: 0.16em; text-transform: uppercase; color: var(--teal); }
    h1 { margin: 2px 0 0; font-size: 20px; font-weight: 700; color: #fff; }
    .model { font: 11px var(--mono); color: var(--muted); }
    .actions { display: flex; gap: 6px; }

    button {
        white-space: nowrap;
        padding: 6px 10px; font-size: 12px; font-weight: 600; cursor: pointer;
        color: var(--text); background: var(--input); border: 1px solid var(--line); border-radius: 6px;
    }
    button:hover:not(:disabled) { border-color: var(--violet); }
    button:disabled { opacity: 0.35; cursor: default; }
    button.primary { background: var(--violet); border-color: var(--violet); color: #fff; }
    button.primary:hover:not(:disabled) { filter: brightness(1.15); }
    button.icon { padding: 6px 9px; }
    button.active { border-color: var(--teal); color: var(--teal); }

    .groups { display: flex; gap: 4px; padding: 10px 14px 0; flex-wrap: wrap; }
    .groups button { padding: 4px 9px; font-size: 11px; border-radius: 999px; }

    .filters { display: flex; gap: 10px; align-items: center; padding: 10px 14px; border-bottom: 1px solid var(--line); }
    .search {
        flex: 1; padding: 6px 10px; font: inherit; font-size: 12px; color: var(--text);
        background: var(--input); border: 1px solid var(--line); border-radius: 6px;
    }
    .search:focus { outline: none; border-color: var(--violet); }
    .toggle { display: flex; align-items: center; gap: 6px; font-size: 12px; color: var(--muted); cursor: pointer; }
    .toggle input { accent-color: var(--teal); }
    .count { font: 600 11px var(--mono); color: var(--teal); }

    .list { flex: 1; overflow-y: auto; padding-bottom: 8px; }
    .list::-webkit-scrollbar { width: 6px; }
    .list::-webkit-scrollbar-thumb { background: var(--line); border-radius: 3px; }
    h2 {
        margin: 0; padding: 14px 14px 4px; font-size: 10px; font-weight: 700;
        letter-spacing: 0.14em; text-transform: uppercase; color: var(--violet);
    }
    .empty { padding: 20px 14px; color: var(--muted); font-size: 12px; text-align: center; }

    .presets { max-height: 220px; overflow-y: auto; border-top: 1px solid var(--line); background: var(--panel-2); padding: 10px 14px; }
    .save { display: flex; gap: 6px; margin-bottom: 8px; }
    .save input {
        flex: 1; padding: 6px 10px; font: inherit; font-size: 12px; color: var(--text);
        background: var(--input); border: 1px solid var(--line); border-radius: 6px;
    }
    .preset { display: flex; gap: 6px; margin-top: 4px; }
    .load { flex: 1; text-align: left; display: flex; justify-content: space-between; }
    .load span { font: 11px var(--mono); color: var(--muted); }

    footer { display: flex; gap: 6px; padding: 12px 14px; border-top: 1px solid var(--line); }
    .spacer { flex: 1; }

    .driving { position: fixed; left: 50%; bottom: 40px; transform: translateX(-50%); text-align: center; }
    .driving p { margin: 8px 0 0; font-size: 12px; color: var(--muted); text-shadow: 0 1px 3px #000; }
</style>
