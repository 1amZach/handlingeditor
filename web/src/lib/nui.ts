// Talks to the Lua side. Outside the game (vite dev) calls just log, so the UI can be worked on in a browser.
declare function GetParentResourceName(): string;

const inGame = typeof (window as any).GetParentResourceName === 'function';

export async function post<T = unknown>(name: string, data: unknown = {}): Promise<T | undefined> {
    if (!inGame) {
        console.debug('[nui]', name, data);
        return undefined;
    }

    const res = await fetch(`https://${GetParentResourceName()}/${name}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data),
    });

    try {
        return (await res.json()) as T;
    } catch {
        return undefined;
    }
}

export function onMessage(handler: (action: string, data: any) => void): () => void {
    const listener = (event: MessageEvent) => {
        const msg = event.data;
        if (msg && typeof msg.action === 'string') handler(msg.action, msg.data);
    };
    window.addEventListener('message', listener);
    return () => window.removeEventListener('message', listener);
}

export { inGame };
