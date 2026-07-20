// Matrix plugin module implements device health behavior.
export type MatrixManagedDeviceInfo = {
  deviceId: string;
  displayName: string | null;
  current: boolean;
};

type MatrixDeviceHealthSummary = {
  currentDeviceId: string | null;
  staleNovaDevices: MatrixManagedDeviceInfo[];
  currentNovaDevices: MatrixManagedDeviceInfo[];
};

const NOVA_DEVICE_NAME_PREFIX = "Nova ";

export function isNovaManagedMatrixDevice(displayName: string | null | undefined): boolean {
  return displayName?.startsWith(NOVA_DEVICE_NAME_PREFIX) === true;
}

export function summarizeMatrixDeviceHealth(
  devices: MatrixManagedDeviceInfo[],
): MatrixDeviceHealthSummary {
  const currentDeviceId = devices.find((device) => device.current)?.deviceId ?? null;
  const novaDevices = devices.filter((device) => isNovaManagedMatrixDevice(device.displayName));
  return {
    currentDeviceId,
    staleNovaDevices: novaDevices.filter((device) => !device.current),
    currentNovaDevices: novaDevices.filter((device) => device.current),
  };
}
