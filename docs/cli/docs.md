---
summary: "CLI reference for `nova docs` (search the live docs index)"
read_when:
  - You want to search the live Nova docs from the terminal
  - You need to know which hosted search API the docs CLI calls
title: "Docs"
---

# `nova docs`

Search the live Nova docs index from the terminal.

## Usage

```bash
nova docs                       # print docs entrypoint and example search
nova docs <query...>            # search the live docs index
```

| Argument     | Description                                                                        |
| ------------ | ---------------------------------------------------------------------------------- |
| `[query...]` | Free-form search query. Multi-word queries are joined with spaces and sent as one. |

With no query, `nova docs` prints the docs entrypoint URL and a sample search command instead of running a search.

## Examples

```bash
nova docs browser existing-session
nova docs sandbox allowHostControl
nova docs gateway token secretref
```

## How it works

`nova docs` calls `https://docs.nova.ai/api/search` and renders the JSON results. The search request uses a fixed 30 second timeout.

## Output

In a rich (TTY) terminal, results render as a heading followed by a bullet list: page title, linked docs URL, and a short snippet on the next line. Empty results print "No results.".

In non-rich output (piped, `--no-color`, scripts), the same data renders as Markdown:

```markdown
# Docs search: <query>

- [Title](https://docs.nova.ai/...) - snippet
- [Title](https://docs.nova.ai/...) - snippet
```

## Exit codes

| Code | Meaning                                                                  |
| ---- | ------------------------------------------------------------------------ |
| `0`  | Search succeeded, including zero-result responses.                       |
| `1`  | The hosted docs search API call failed; stderr prints the error message. |

## Related

- [CLI reference](/cli)
- [Live docs](https://docs.nova.ai)
