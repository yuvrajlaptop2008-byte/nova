#!/usr/bin/env -S node --import tsx
// Nova release ClawHub plan CLI emits release workflow routing as JSON.

import { pathToFileURL } from "node:url";
import {
  buildNovaReleaseClawHubPlan,
  parseNovaReleaseClawHubPlanArgs,
} from "./lib/nova-release-clawhub-plan.ts";

if (import.meta.url === pathToFileURL(process.argv[1] ?? "").href) {
  const args = parseNovaReleaseClawHubPlanArgs(process.argv.slice(2));
  const plan = await buildNovaReleaseClawHubPlan(args);
  console.log(JSON.stringify(plan, null, 2));
}
