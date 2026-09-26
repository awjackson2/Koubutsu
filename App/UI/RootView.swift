import KoubutsuCore
import SwiftUI

struct RootView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            Text("Koubutsu \(CoreInfo.version)")
                .foregroundStyle(.white)
        }
    }
}
