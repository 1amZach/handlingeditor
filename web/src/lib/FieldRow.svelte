<script lang="ts">
    import type { Field, Value, Vec } from './types';
    import { decimals, same } from './meta';

    interface Props {
        field: Field;
        value: Value;
        stock: Value;
        // commit is false while dragging, true once the change is final (for undo history)
        onchange: (value: Value, commit: boolean) => void;
    }

    let { field, value, stock, onchange }: Props = $props();

    const places = $derived(decimals(field.step));
    const changed = $derived(!same(value, stock));
    const pct = (n: number) => ((n - field.min) / (field.max - field.min)) * 100;
    const fmt = (n: number) => n.toFixed(places);

    function setNumber(raw: string, commit: boolean) {
        const n = Number(raw);
        if (Number.isNaN(n)) return;
        onchange(Math.min(field.max, Math.max(field.min, n)), commit);
    }

    function setAxis(axis: keyof Vec, raw: string, commit: boolean) {
        const n = Number(raw);
        if (Number.isNaN(n)) return;
        const v = { ...(value as Vec), [axis]: Math.min(field.max, Math.max(field.min, n)) };
        onchange(v, commit);
    }
</script>

<div class="row" class:changed>
    <div class="head">
        <span class="label" title={field.name}>
            {field.label}
            {#if field.unit}<span class="unit">{field.unit}</span>{/if}
        </span>
        {#if field.hint}<span class="hint">{field.hint}</span>{/if}
        {#if changed}
            <button class="reset" title="Back to stock" onclick={() => onchange(stock, true)}>stock</button>
        {/if}
    </div>

    {#if field.type === 'vec'}
        {#each ['x', 'y', 'z'] as const as axis}
            {@const v = (value as Vec)[axis]}
            {@const s = (stock as Vec)[axis]}
            <div class="line">
                <span class="axis">{axis}</span>
                <div class="track">
                    <span class="stock" style:left="{pct(s)}%"></span>
                    <input type="range" min={field.min} max={field.max} step={field.step} value={v}
                        oninput={(e) => setAxis(axis, e.currentTarget.value, false)}
                        onchange={(e) => setAxis(axis, e.currentTarget.value, true)} />
                </div>
                <input class="num" type="number" min={field.min} max={field.max} step={field.step} value={fmt(v)}
                    onchange={(e) => setAxis(axis, e.currentTarget.value, true)} />
            </div>
        {/each}
    {:else}
        {@const v = value as number}
        <div class="line">
            <div class="track">
                <span class="stock" style:left="{pct(stock as number)}%"></span>
                <input type="range" min={field.min} max={field.max} step={field.step} value={v}
                    oninput={(e) => setNumber(e.currentTarget.value, false)}
                    onchange={(e) => setNumber(e.currentTarget.value, true)} />
            </div>
            <input class="num" type="number" min={field.min} max={field.max} step={field.step} value={fmt(v)}
                onchange={(e) => setNumber(e.currentTarget.value, true)} />
        </div>
    {/if}
</div>

<style>
    .row {
        padding: 10px 14px;
        border-left: 2px solid transparent;
        transition: background 0.15s;
    }
    .row:hover { background: var(--hover); }
    .row.changed { border-left-color: var(--teal); }

    .head { display: flex; align-items: baseline; gap: 8px; margin-bottom: 6px; }
    .label { font-weight: 600; font-size: 13px; color: var(--text); }
    .unit { color: var(--muted); font-weight: 500; font-size: 11px; margin-left: 4px; }
    .hint { color: var(--muted); font-size: 11px; }
    .reset {
        margin-left: auto;
        font: inherit; font-size: 11px; letter-spacing: 0.04em;
        color: var(--teal); background: none; border: 1px solid var(--teal-dim);
        border-radius: 4px; padding: 1px 6px; cursor: pointer;
    }
    .reset:hover { background: var(--teal-dim); }

    .line { display: flex; align-items: center; gap: 10px; }
    .line + .line { margin-top: 4px; }
    .axis { width: 10px; color: var(--muted); font-size: 11px; text-transform: uppercase; }

    .track { position: relative; flex: 1; height: 18px; display: flex; align-items: center; }
    .stock {
        position: absolute; top: 2px; width: 2px; height: 14px; margin-left: -1px;
        background: var(--muted); opacity: 0.6; pointer-events: none; border-radius: 1px;
    }

    input[type='range'] {
        -webkit-appearance: none; appearance: none;
        width: 100%; height: 4px; border-radius: 2px; margin: 0;
        background: var(--track); outline: none;
    }
    input[type='range']::-webkit-slider-thumb {
        -webkit-appearance: none; width: 14px; height: 14px; border-radius: 50%;
        background: var(--violet); border: 2px solid #fff; cursor: pointer;
        box-shadow: 0 0 0 3px rgba(156, 44, 241, 0.25);
    }
    .changed input[type='range']::-webkit-slider-thumb { background: var(--teal); box-shadow: 0 0 0 3px rgba(43, 217, 204, 0.25); }

    .num {
        width: 78px; padding: 4px 6px; text-align: right;
        font: 12px var(--mono); color: var(--text);
        background: var(--input); border: 1px solid var(--line); border-radius: 4px;
    }
    .num:focus { outline: none; border-color: var(--violet); }
    .num::-webkit-inner-spin-button { opacity: 0.4; }
</style>
