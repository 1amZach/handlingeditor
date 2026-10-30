import type { Field, Values, Vec } from './types';

const f6 = (n: number) => n.toFixed(6);

// Builds a CHandlingData item you can paste into handling.meta
export function toMeta(handlingName: string, fields: Field[], values: Values): string {
    const lines = [
        '<Item type="CHandlingData">',
        `  <handlingName>${handlingName.toUpperCase()}</handlingName>`,
    ];

    for (const field of fields) {
        const value = values[field.name];
        if (value === undefined) continue;

        if (field.type === 'vec') {
            const v = value as Vec;
            lines.push(`  <${field.name} x="${f6(v.x)}" y="${f6(v.y)}" z="${f6(v.z)}" />`);
        } else if (field.type === 'int') {
            lines.push(`  <${field.name} value="${Math.round(value as number)}" />`);
        } else {
            lines.push(`  <${field.name} value="${f6(value as number)}" />`);
        }
    }

    lines.push('</Item>');
    return lines.join('\n');
}

export function same(a: unknown, b: unknown): boolean {
    if (typeof a === 'number' && typeof b === 'number') return Math.abs(a - b) < 1e-4;
    if (a && b && typeof a === 'object' && typeof b === 'object') {
        const va = a as Vec, vb = b as Vec;
        return same(va.x, vb.x) && same(va.y, vb.y) && same(va.z, vb.z);
    }
    return a === b;
}

// steps like 0.005 need 3 decimals, 10 needs none
export function decimals(step: number): number {
    const s = String(step);
    return s.includes('.') ? s.split('.')[1]!.length : 0;
}
