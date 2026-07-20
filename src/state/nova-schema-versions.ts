export type NovaSchemaVersions = {
  state: number;
  agent: number;
};

export function parseNovaSchemaVersions(value: unknown): NovaSchemaVersions | undefined {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    return undefined;
  }
  const record = value as Record<string, unknown>;
  if (
    !Number.isInteger(record.state) ||
    (record.state as number) < 0 ||
    !Number.isInteger(record.agent) ||
    (record.agent as number) < 0
  ) {
    return undefined;
  }
  return { state: record.state as number, agent: record.agent as number };
}

export function parsePackageNovaSchemaVersions(
  packageJson: unknown,
): NovaSchemaVersions | undefined {
  if (!packageJson || typeof packageJson !== "object" || Array.isArray(packageJson)) {
    return undefined;
  }
  const nova = (packageJson as Record<string, unknown>).nova;
  if (!nova || typeof nova !== "object" || Array.isArray(nova)) {
    return undefined;
  }
  return parseNovaSchemaVersions((nova as Record<string, unknown>).schemaVersions);
}
