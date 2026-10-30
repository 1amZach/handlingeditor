export type Vec = { x: number; y: number; z: number };
export type Value = number | Vec;
export type Values = Record<string, Value>;

export interface Field {
    name: string;
    group: string;
    label: string;
    type: 'float' | 'int' | 'vec';
    min: number;
    max: number;
    step: number;
    unit?: string;
    hint?: string;
}

export interface Telemetry {
    kmh: number;
    rpm: number;
    gear: number;
    gLat: number;
    gLong: number;
    top: number;
    timing?: number;
}

export interface Preset {
    model?: string;
    values: Values;
}

export interface OpenData {
    fields: Field[];
    vehicle: { label: string; model: string };
    stock: Values;
    values: Values;
    presets: Record<string, Preset> | Preset[];
}
