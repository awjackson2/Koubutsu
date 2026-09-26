/// Platform-agnostic core of Koubutsu.
///
/// Everything in this module must compile with Foundation only, on Linux as well as Apple platforms,
/// so that pipeline logic is testable without Xcode. Apple-framework adapters live in the app target.
public enum CoreInfo {
    public static let version = "0.1.0"
}
