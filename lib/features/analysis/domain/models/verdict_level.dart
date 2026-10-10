/// Result category shown to the user.
///
/// There is no "safe" value on purpose: finding no known signal
/// does not prove that a message can be trusted.
enum VerdictLevel {
  noSignalFound,
  suspicious,
  dangerous,
}
