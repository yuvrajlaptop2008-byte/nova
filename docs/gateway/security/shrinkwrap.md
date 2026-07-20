---
summary: "Plain-English and technical explanation of npm shrinkwrap in Nova releases"
read_when:
  - You want to know what npm shrinkwrap means in an Nova release
  - You are reviewing package lockfiles, dependency changes, or supply-chain risk
  - You are validating root or plugin npm packages before publishing
title: "npm shrinkwrap"
---

Nova source checkouts use `pnpm-lock.yaml`. Published Nova npm packages use `npm-shrinkwrap.json`, npm's publishable dependency lockfile, so package installs use the dependency graph reviewed during release.

## Why it matters

Shrinkwrap is a receipt for the dependency tree that ships with an npm package: it tells npm which exact transitive versions to install.

| File                  | Where it matters      | What it means                 |
| --------------------- | --------------------- | ----------------------------- |
| `pnpm-lock.yaml`      | Nova source checkout  | Maintainer dependency graph   |
| `npm-shrinkwrap.json` | Published npm package | npm install graph for users   |
| `package-lock.json`   | Local npm apps        | Not the Nova publish contract |

For Nova releases this means:

- the published package does not ask npm to invent a fresh dependency graph at install time;
- dependency changes are reviewable because they land in a lockfile diff;
- release validation tests the same graph users will install;
- package-size or native-dependency surprises surface before publishing.

Shrinkwrap is not a sandbox. It does not make a dependency safe by itself, and it does not replace host isolation, `nova security audit`, package provenance, or install smoke tests.

Nova is a gateway, plugin host, model router, and agent runtime, so a default install affects startup time, disk use, native package downloads, and supply-chain exposure. Shrinkwrap gives release review a stable boundary: reviewers see transitive dependency movement, validators reject unexpected lockfile drift, and plugin packages carry their own locked dependency graph instead of relying on the root package.

## Generating and checking

The root `nova` npm package, Nova-owned npm plugin packages (for example `@nova/discord`), and publishable workspace packages such as [`@nova/ai`](/reference/nova-ai) include `npm-shrinkwrap.json` when they publish. Workspace dependencies are omitted from the root shrinkwrap because they publish beside the root package; each publishable workspace package pins its own transitive tree instead. Suitable plugin packages can also publish with explicit `bundledDependencies`, carrying their runtime dependency files in the plugin tarball instead of relying only on install-time resolution.

```bash
# All shrinkwrap-managed packages (root + publishable plugins)
pnpm deps:shrinkwrap:generate
pnpm deps:shrinkwrap:check

# Root package only
pnpm deps:shrinkwrap:root:generate
pnpm deps:shrinkwrap:root:check

# Only packages affected by the current changeset
pnpm deps:shrinkwrap:changed:generate
pnpm deps:shrinkwrap:changed:check
```

The generator resolves npm's publishable lock format but rejects generated package versions that are not already present in `pnpm-lock.yaml`. That keeps the pnpm dependency age, override, and patch-review boundary intact.

Review these as security-sensitive:

- `pnpm-lock.yaml`
- `npm-shrinkwrap.json`
- bundled plugin dependency payloads
- any `package-lock.json` diff

Nova package validators require shrinkwrap in new root package tarballs and reject `package-lock.json` for published packages. The plugin npm publish path checks plugin-local shrinkwrap, installs package-local bundled dependencies, then packs or publishes.

## Inspecting a published package

Root package:

```bash
npm pack nova@<version> --json --pack-destination /tmp/nova-pack
tar -tf /tmp/nova-pack/nova-<version>.tgz | grep '^package/npm-shrinkwrap.json$'
```

Plugin package:

```bash
npm pack @nova/discord@<version> --json --pack-destination /tmp/nova-plugin-pack
tar -tf /tmp/nova-plugin-pack/nova-discord-<version>.tgz | grep '^package/npm-shrinkwrap.json$'
tar -tf /tmp/nova-plugin-pack/nova-discord-<version>.tgz | grep '^package/node_modules/'
```

Background: [npm-shrinkwrap.json](https://docs.npmjs.com/cli/v11/configuring-npm/npm-shrinkwrap-json).
