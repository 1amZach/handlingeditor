<script lang="ts">
    import type { Telemetry } from './types';

    interface Props {
        data: Telemetry | null;
        launch: { time: number; best: number } | null;
        compact?: boolean;
    }

    let { data, launch, compact = false }: Props = $props();

    const kmh = $derived(Math.round(data?.kmh ?? 0));
    const rpm = $derived(Math.max(0, Math.min(1, data?.rpm ?? 0)));
    const gear = $derived(data ? (data.gear === 0 ? 'R' : String(data.gear)) : '-');
    const g = (n: number | undefined) => (n ?? 0).toFixed(2);
</script>

<div class="tele" class:compact>
    <div class="speed">
        <span class="big">{kmh}</span><span class="small">km/h</span>
        <span class="mph">{Math.round(kmh * 0.621371)} mph</span>
    </div>

    <div class="gear">{gear}</div>

    <div class="rpm">
        <div class="bar"><div class="fill" class:redline={rpm > 0.92} style:width="{rpm * 100}%"></div></div>
        <div class="stats">
            <span>LAT <b>{g(data?.gLat)}g</b></span>
            <span>LONG <b>{g(data?.gLong)}g</b></span>
            <span>TOP <b>{Math.round(data?.top ?? 0)}</b></span>
        </div>
    </div>

    <div class="launch">
        <span class="lbl">0-100</span>
        {#if data?.timing !== undefined && data?.timing !== null}
            <span class="time live">{data.timing.toFixed(2)}s</span>
        {:else if launch}
            <span class="time">{launch.time.toFixed(2)}s</span>
            <span class="best">best {launch.best.toFixed(2)}</span>
        {:else}
            <span class="time idle">stop, then go</span>
        {/if}
    </div>
</div>

<style>
    .tele {
        display: grid;
        grid-template-columns: auto auto 1fr auto;
        align-items: center;
        gap: 14px;
        padding: 12px 14px;
        background: var(--panel-2);
        border-bottom: 1px solid var(--line);
    }
    .compact {
        border: 1px solid var(--line);
        border-radius: 10px;
        background: rgba(10, 8, 22, 0.88);
        box-shadow: 0 10px 30px rgba(0, 0, 0, 0.5);
        width: 520px;
    }

    .speed { display: flex; align-items: baseline; gap: 4px; min-width: 96px; flex-wrap: wrap; }
    .big { font: 700 30px var(--mono); line-height: 1; color: #fff; }
    .small { font-size: 11px; color: var(--muted); }
    .mph { flex-basis: 100%; font-size: 11px; color: var(--muted); }

    .gear {
        width: 38px; height: 38px; display: grid; place-items: center;
        font: 700 20px var(--mono); color: var(--teal);
        border: 1px solid var(--teal-dim); border-radius: 8px;
    }

    .bar { height: 6px; background: var(--track); border-radius: 3px; overflow: hidden; }
    .fill { height: 100%; background: linear-gradient(90deg, var(--teal), var(--violet)); transition: width 0.06s linear; }
    .fill.redline { background: #e5484d; }
    .stats { display: flex; gap: 12px; margin-top: 6px; font-size: 10px; letter-spacing: 0.06em; color: var(--muted); }
    .stats b { font: 600 11px var(--mono); color: var(--text); }

    .launch { display: flex; flex-direction: column; align-items: flex-end; min-width: 84px; }
    .lbl { font-size: 10px; letter-spacing: 0.08em; color: var(--muted); }
    .time { font: 700 18px var(--mono); color: #fff; }
    .time.live { color: var(--teal); }
    .time.idle { font: 500 11px var(--sans); color: var(--muted); }
    .best { font-size: 10px; color: var(--teal); }
</style>
