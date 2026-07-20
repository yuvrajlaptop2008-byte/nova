# Nova GMI Cloud Provider

Official Nova provider plugin for hosted GMI Cloud models through an
OpenAI-compatible API.

Install from Nova:

```bash
nova plugins install @nova/gmi-provider
nova gateway restart
```

Configure a GMI Cloud API key, then select models with refs such as
`gmi/google/gemini-3.1-flash-lite`.
