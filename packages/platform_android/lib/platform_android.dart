/// Android platform access.
///
/// MediaStore queries, `AudioManager` properties and device information,
/// called through `package:jni` with jnigen-generated bindings. No hand-written
/// Kotlin or Java (D-012, AGENTS.md §7).
///
/// Public API (also listed in `README.md`): `MediaStoreGateway`,
/// `AudioManagerInfo` and the device probe are added in S5 and M2.
library;
