import "./web-fetch.js";

type WebFetchTestApi = {
  sanitizeWebFetchUrl(raw: string): string;
};

function getTestApi(): WebFetchTestApi {
  return (globalThis as Record<PropertyKey, unknown>)[
    Symbol.for("nova.webFetchTestApi")
  ] as WebFetchTestApi;
}

export const sanitizeWebFetchUrl: WebFetchTestApi["sanitizeWebFetchUrl"] = (raw) =>
  getTestApi().sanitizeWebFetchUrl(raw);
