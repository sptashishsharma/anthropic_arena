/// Sign-in configuration that an admin may want to change without touching
/// auth logic.
abstract final class AuthConfig {
  /// Which Microsoft (Entra ID) accounts may sign in:
  ///
  /// - `'common'`        — work/school accounts from **any** organization,
  ///                       plus personal Microsoft accounts. (default)
  /// - `'organizations'` — work/school accounts from any organization only;
  ///                       personal outlook.com/hotmail.com accounts blocked.
  /// - `'consumers'`     — personal Microsoft accounts only.
  /// - a tenant id       — lock sign-in to **one** company. Paste the
  ///                       "Directory (tenant) ID" from the Azure portal
  ///                       (Entra ID → Overview), e.g.
  ///                       `'72f988bf-86f1-41af-91ab-2d7cd011db47'`.
  ///
  /// Note this is a convenience filter on the sign-in screen, not a security
  /// boundary — enforce hard restrictions in Firebase/Entra as well if you
  /// need them.
  static const microsoftTenant = 'common';
}
