/// Web implementation of Delegate.
///
/// On web, delegates are no-ops since GPU acceleration is handled
/// by TF.js backend selection.
abstract class Delegate {
  /// On web, returns null (no FFI pointer).
  dynamic get base => null;

  /// No-op on web.
  void delete() {}
}
