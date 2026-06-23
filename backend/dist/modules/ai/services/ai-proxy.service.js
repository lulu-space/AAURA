import { env } from '../../../config/env.js';
import { ApiError } from '../../../core/errors/api-error.js';
const AI_REQUEST_TIMEOUT_MS = 45_000;
function aiBaseUrl() {
    return env.AI_SERVICE_URL.replace(/\/$/, '');
}
export async function proxyToAi(path, init = {}) {
    const normalizedPath = path.startsWith('/') ? path : `/${path}`;
    const url = `${aiBaseUrl()}${normalizedPath}`;
    let response;
    try {
        response = await fetch(url, {
            ...init,
            signal: AbortSignal.timeout(AI_REQUEST_TIMEOUT_MS)
        });
    }
    catch (error) {
        throw new ApiError(503, 'AI service is unavailable.', {
            url,
            error: error instanceof Error ? error.message : String(error)
        });
    }
    const text = await response.text();
    let body = text;
    if (text) {
        try {
            body = JSON.parse(text);
        }
        catch {
            body = text;
        }
    }
    return { status: response.status, body };
}
