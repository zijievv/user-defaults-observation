import Observation
import SwiftUI
import UserDefaultsObservation

enum Amount: Codable, CustomStringConvertible {
    case mL(Double)
    case gram(Double)

    var description: String {
        switch self {
        case .mL(let double): "\(double) mL"
        case .gram(let double): "\(double) g"
        }
    }
}

struct Record: Codable, CustomStringConvertible {
    let id: UUID
    var amount: Amount

    init(id: UUID = .init(), amount: Amount) {
        self.id = id
        self.amount = amount
    }

    var description: String { "id: \(id)\namount: \(amount)" }
}

@Observable
class Model {
    @ObservableUserDefaults(key: "text", store: Self.store)
    @ObservationIgnored
    var text: String = "Text"

    @ObservableUserDefaults(key: "value")
    @ObservationIgnored
    var value: Int = 1

    @ObservableUserDefaults(key: "record")
    @ObservationIgnored
    var record: Record = .init(amount: .mL(100))

    static let store = UserDefaults(suiteName: "Store")!
}

struct ContentView: View {
    @AppStorage("text", store: Model.store) private var text: String = "appstoragetext"
    @AppStorage("record") private var recordData: Data?
    @AppStorage("value") private var value: Int = -1
    var model: Model = .init()

    var body: some View {
        VStack {
            TextField("text appstorage", text: $text)
            TextField("text", text: Bindable(model).text)
            Divider()
            Text("App storage value: \(value)")
            Button("Plus") { value += 1 }
            Divider()
            Text("Observable value: \(model.value)")
            Button("Minus") { model.value -= 1 }
            Divider()
            Text("Record:\n\(model.record)")
            Button("Random record") {
                model.record =
                    switch model.record.amount {
                    case .mL: .init(amount: .gram(Double((0...100).randomElement()!)))
                    case .gram: .init(amount: .mL(Double((0...100).randomElement()!)))
                    }
            }
            if let data = recordData {
                Text("Data")
                if let record = try? JSONDecoder().decode(Record.self, from: data) {
                    Text("Record:\n\(record)")
                    Button("Random record data") {
                        let new: Record =
                            switch record.amount {
                            case .mL: .init(amount: .gram(Double((0...100).randomElement()!)))
                            case .gram: .init(amount: .mL(Double((0...100).randomElement()!)))
                            }
                        recordData = try? JSONEncoder().encode(new)
                    }
                }
            }
        }
        .font(.footnote)
        .buttonStyle(.borderedProminent)
        .padding()
    }
}

#Preview {
    ContentView()
}
