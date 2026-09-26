import KoubutsuCore
import Observation

/// Loads the dictionary in the background at launch and exposes it once ready.
@MainActor
@Observable
final class DictionaryProvider {
    enum State: Equatable {
        case loading
        case ready
        case failed(String)
    }

    private(set) var state: State = .loading
    @ObservationIgnored private(set) var store: (any DictionaryStore)?
    /// Shared lookup (its de-inflection rule table is built once).
    @ObservationIgnored private(set) var lookup: DictionaryLookup?

    func load() async {
        guard store == nil else { return }
        state = .loading
        let result = await Task.detached(priority: .utility) { () -> Result<SQLiteDictionaryStore, any Error> in
            Result { try SQLiteDictionaryStore.open() }
        }.value
        switch result {
        case .success(let opened):
            store = opened
            lookup = DictionaryLookup(store: opened)
            state = .ready
        case .failure(let error):
            state = .failed(String(describing: error))
        }
    }
}
