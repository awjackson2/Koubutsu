import KoubutsuCore
import SwiftUI

extension EnvironmentValues {
    /// The window's layout class (10.1.0), set by `RootView` from the window size.
    @Entry var layoutClass: LayoutClass = .regular
}
