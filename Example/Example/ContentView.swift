import Observation
import SwiftUI
import UserDefaultsObservation

@Observable
class Model {
    @ObservableUserDefaults(key: "text", store: Self.store)
    @ObservationIgnored
    var text: String = "Text"

    @ObservableUserDefaults(key: "value")
    @ObservationIgnored
    var value: Int = 1

    static let store = UserDefaults(suiteName: "Store")!
}

struct ContentView: View {
    @AppStorage("value") private var value: Int = -1
    var model: Model = .init()

    var body: some View {
        VStack {
            Text("App storage value: \(value)")
            Button("Plus") { value += 1 }
            Divider()
            Text("Observable value: \(model.value)")
            Button("Minus") { model.value -= 1 }
        }
        .buttonStyle(.borderedProminent)
    }
}

#Preview {
    ContentView()
}
