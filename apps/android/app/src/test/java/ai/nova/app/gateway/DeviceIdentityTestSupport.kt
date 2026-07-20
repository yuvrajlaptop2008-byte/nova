package ai.nova.app.gateway

import ai.nova.app.SecurePrefs
import android.content.Context

internal fun testDeviceIdentityStore(context: Context): DeviceIdentityStore {
  val backing =
    context.getSharedPreferences(
      "nova.node.secure.test.device-identity",
      Context.MODE_PRIVATE,
    )
  return DeviceIdentityStore.withPrefs(
    context,
    SecurePrefs(context, securePrefsOverride = backing),
  )
}
