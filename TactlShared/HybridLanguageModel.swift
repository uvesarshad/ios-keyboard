import Foundation

// MARK: - Seed vocabulary
// Pre-computed from common conversational English (messaging, email, notes).
// Counts are relative frequencies — higher = more likely suggestion.
// Personal typing overwrites these over time (5× weight on personal counts).

private enum Seed {

    static let bigrams: [String: [String: Int]] = [
        "i":        ["am":90,"will":85,"have":80,"think":75,"know":70,"don't":70,
                     "can":65,"would":60,"need":55,"just":55,"want":50,"love":45,"got":40,"feel":40],
        "you":      ["are":90,"can":85,"have":80,"will":75,"know":70,"should":65,
                     "need":60,"want":55,"might":50,"could":45,"too":40,"get":40,"were":35],
        "we":       ["can":85,"will":80,"should":75,"need":70,"have":65,"are":60,
                     "could":55,"might":50,"want":45,"go":40,"get":40],
        "it":       ["is":90,"was":85,"will":75,"would":70,"could":65,"might":60,
                     "seems":50,"looks":50,"feels":45,"makes":45,"works":40,"helps":40],
        "the":      ["same":80,"best":75,"day":70,"time":70,"way":65,"most":65,
                     "new":60,"next":60,"first":60,"last":55,"only":55,"right":50],
        "to":       ["be":90,"get":85,"go":80,"do":80,"make":75,"see":70,"have":70,
                     "know":65,"find":65,"use":60,"help":60,"take":55,"give":55,"come":50],
        "is":       ["a":90,"the":85,"not":80,"so":70,"very":65,"really":60,"just":55,
                     "also":50,"still":50,"already":45,"always":45,"good":40,"great":40],
        "are":      ["you":90,"we":80,"the":70,"a":65,"not":60,"so":55,"very":50,"also":45,"still":40],
        "do":       ["you":90,"we":75,"I":70,"that":65,"this":60,"it":55,"not":50,"your":45],
        "don't":    ["know":90,"think":80,"have":70,"want":70,"see":60,"like":55,
                     "need":55,"worry":50,"understand":45,"forget":45,"care":40],
        "can":      ["you":90,"we":80,"I":70,"be":65,"help":65,"get":60,"do":60,
                     "see":55,"also":50,"go":50,"find":45,"still":45],
        "will":     ["be":90,"have":80,"let":70,"get":65,"make":65,"do":60,"help":60,
                     "take":55,"try":55,"need":50,"send":45,"go":45,"come":45],
        "how":      ["are":90,"is":80,"do":70,"can":65,"much":60,"many":55,"long":50,
                     "about":45,"come":40,"so":40],
        "what":     ["do":90,"is":85,"are":75,"about":65,"if":60,"time":55,"kind":45,"else":45],
        "let":      ["me":90,"you":80,"us":70,"it":60,"them":50],
        "please":   ["let":80,"help":75,"send":65,"check":65,"make":60,"find":55,
                     "tell":55,"be":50,"see":45,"do":45],
        "thank":    ["you":95,"god":40],
        "thanks":   ["for":90,"a":60,"so":55],
        "sorry":    ["for":85,"about":75,"I":60,"to":55,"that":50],
        "good":     ["morning":90,"afternoon":75,"evening":70,"night":65,"idea":60,
                     "luck":55,"time":50,"job":50,"to":45,"at":40],
        "great":    ["idea":85,"job":80,"time":70,"work":65,"to":55,"for":50,"thanks":45,"point":45],
        "ok":       ["sounds":80,"I":70,"will":65,"let":60,"that":55,"so":50],
        "okay":     ["sounds":80,"I":70,"will":65,"let":60,"that":55,"so":50],
        "yes":      ["please":85,"I":70,"of":60,"that":55,"definitely":50],
        "no":       ["problem":90,"worries":85,"I":65,"that":55,"one":50,"idea":50,"way":45],
        "hey":      ["how":80,"are":75,"I":65,"can":60,"what":55,"there":50],
        "hi":       ["how":80,"I":70,"there":65,"everyone":55],
        "hello":    ["how":80,"I":70,"there":65,"everyone":55],
        "i'm":      ["not":85,"so":75,"a":70,"going":65,"sorry":60,"sure":60,
                     "glad":55,"happy":55,"here":55,"working":50,"really":50,"very":50],
        "it's":     ["a":90,"not":85,"so":80,"the":75,"very":70,"really":65,"just":60,
                     "been":55,"great":55,"good":55,"fine":50,"hard":45,"easy":45],
        "that's":   ["a":85,"the":80,"not":75,"so":70,"great":65,"good":60,
                     "right":55,"true":55,"what":50,"really":50,"fine":45],
        "there":    ["is":90,"are":85,"was":75,"were":65,"will":60,"might":55,"could":50,"should":45],
        "this":     ["is":90,"was":80,"will":70,"would":65,"could":60,"means":55,"should":50,"the":45],
        "have":     ["a":90,"been":80,"to":75,"no":65,"some":60,"any":55,"already":55,"not":50],
        "want":     ["to":90,"a":70,"more":65,"this":60,"that":55,"it":50],
        "need":     ["to":90,"a":70,"some":65,"more":60,"help":55,"time":50],
        "know":     ["what":80,"how":75,"if":70,"that":65,"you":60,"I":55,"about":50,"where":45],
        "think":    ["I":75,"we":70,"it":65,"that":60,"about":55,"so":50,"you":45],
        "make":     ["sure":90,"it":75,"a":65,"this":60,"up":55,"your":50,"that":45],
        "just":     ["want":75,"need":70,"checking":65,"wanted":60,"let":55,"got":55,"saw":50],
        "get":      ["the":80,"a":75,"back":70,"to":65,"some":60,"it":55,"there":55,"home":50,"ready":50],
        "see":      ["you":85,"if":75,"what":65,"how":60,"it":55,"that":55,"this":50,"the":45],
        "going":    ["to":90,"on":70,"back":65,"home":60,"out":55,"up":50,"down":45,"well":40],
        "looks":    ["good":85,"great":80,"like":70,"so":60,"amazing":55],
        "sounds":   ["good":90,"great":85,"amazing":70,"like":60,"perfect":55,"fun":50],
        "hope":     ["you":85,"that":75,"we":65,"it":60,"this":55,"everything":50],
        "still":    ["here":75,"working":65,"waiting":60,"on":55,"at":50,"in":45,"the":40],
        "already":  ["done":75,"there":65,"have":60,"had":55,"been":55,"got":50],
        "maybe":    ["we":80,"I":75,"you":70,"later":65,"next":60,"tomorrow":55,"another":50],
        "would":    ["be":90,"have":80,"like":70,"you":65,"love":55,"appreciate":50],
        "could":    ["be":85,"you":75,"we":70,"I":65,"also":60,"help":55],
        "should":   ["be":85,"we":75,"I":70,"you":65,"have":60],
        "might":    ["be":85,"have":70,"not":65,"also":55,"need":50,"want":45],
        "let's":    ["go":90,"do":80,"get":75,"make":65,"try":60,"have":55,"talk":50,"see":45],
        "i'll":     ["be":85,"let":75,"try":70,"get":65,"send":60,"check":55,"do":55,"make":50],
        "i've":     ["been":85,"got":75,"had":65,"seen":60,"done":55,"already":50],
        "i'd":      ["like":85,"love":75,"be":65,"rather":60,"appreciate":55,"suggest":45],
        "you're":   ["right":80,"welcome":75,"not":70,"so":65,"the":60,"a":55,"going":50,"doing":45],
        "we're":    ["going":80,"not":70,"so":65,"a":60,"the":55,"working":50,"all":45],
        "they":     ["are":85,"were":75,"will":65,"have":60,"can":55,"might":50,"should":45],
        "when":     ["you":80,"we":70,"I":65,"it":60,"the":55,"is":50,"are":45,"do":40],
        "where":    ["are":80,"is":70,"you":65,"we":60,"I":55,"the":50,"do":45],
        "why":      ["don't":80,"are":70,"is":65,"would":60,"do":55,"can't":50,"not":45],
        "about":    ["the":80,"it":70,"this":65,"that":60,"you":55,"your":50,"a":45],
        "with":     ["the":80,"you":75,"a":70,"me":65,"us":60,"your":55,"my":50,"this":45],
        "for":      ["the":80,"you":75,"a":70,"me":65,"us":60,"your":55,"this":50,"that":45,"it":40],
        "on":       ["the":80,"it":70,"my":65,"your":60,"this":55,"a":50,"time":45],
        "at":       ["the":80,"a":70,"home":65,"work":60,"school":55,"this":50,"that":45],
        "from":     ["the":80,"you":70,"a":65,"my":60,"your":55,"this":50,"it":45],
        "but":      ["I":85,"we":75,"it":70,"the":65,"that":60,"you":55,"this":50,"not":45],
        "and":      ["I":75,"we":70,"the":65,"you":60,"it":55,"a":50,"this":45,"that":40],
        "or":       ["you":70,"I":65,"we":60,"the":55,"a":50,"not":45,"if":40],
        "if":       ["you":85,"we":75,"I":70,"it":65,"the":60,"that":55,"this":50,"not":45],
        "so":       ["I":80,"we":75,"you":70,"it":65,"the":60,"that":55,"this":50,"much":45,"glad":45],
        "not":      ["sure":80,"a":70,"the":65,"that":60,"this":55,"really":50,"yet":45,"at":40],
        "really":   ["good":80,"great":75,"nice":70,"want":65,"need":60,"think":55,"like":50,"appreciate":45],
        "very":     ["much":85,"good":75,"well":70,"nice":65,"happy":60,"sorry":55,"glad":50,"kind":45],
        "much":     ["better":80,"more":70,"less":65,"easier":60,"harder":55,"faster":50],
        "more":     ["than":75,"time":70,"information":65,"details":60,"help":55,"work":50,"people":45],
        "some":     ["time":75,"help":70,"more":65,"people":60,"things":55,"work":50,"information":45],
        "any":      ["time":75,"help":70,"questions":65,"issues":60,"problems":55,"information":50,"updates":45],
    ]

    static let trigrams: [String: [String: [String: Int]]] = [
        "i": [
            "am":       ["going":85,"not":80,"a":70,"working":65,"here":60,"so":55,"at":50,"in":45,"sorry":45],
            "will":     ["be":90,"let":80,"try":70,"get":65,"send":60,"check":55,"call":50,"do":50],
            "have":     ["a":85,"been":80,"to":70,"no":65,"some":60,"already":55,"not":50,"the":45],
            "don't":    ["know":90,"think":80,"want":70,"have":65,"see":60,"understand":55,"like":50,"need":45],
            "can't":    ["wait":85,"believe":75,"find":65,"see":60,"make":55,"do":50,"get":45,"come":40],
            "think":    ["we":80,"it":75,"you":70,"that":65,"I":60,"so":55,"about":50,"the":45],
            "just":     ["wanted":85,"want":75,"need":65,"got":60,"saw":55,"realized":50,"checked":45],
            "need":     ["to":90,"a":70,"some":65,"help":60,"more":55,"time":50],
            "want":     ["to":90,"a":75,"more":65,"this":60,"that":55],
            "know":     ["what":80,"how":75,"that":65,"if":60,"you":55,"I":50],
            "would":    ["like":85,"love":75,"be":65,"appreciate":55,"suggest":50],
            "love":     ["you":90,"this":70,"it":65,"that":60,"how":55],
            "got":      ["the":75,"a":70,"it":65,"your":60,"some":55,"this":50],
            "feel":     ["like":80,"so":70,"a":60,"good":55,"great":50,"bad":45],
        ],
        "you": [
            "are":      ["the":80,"a":75,"not":70,"so":65,"very":60,"right":55,"doing":50,"going":45],
            "can":      ["do":80,"go":75,"get":70,"see":65,"find":60,"use":55,"also":50,"help":45],
            "have":     ["a":80,"been":75,"to":70,"the":65,"no":60,"any":55,"already":50,"not":45],
            "should":   ["be":80,"try":70,"check":65,"see":60,"go":55,"do":50,"get":45,"have":40],
            "know":     ["what":80,"how":70,"that":65,"if":60,"I":55,"where":50],
            "don't":    ["have":80,"need":70,"want":65,"know":60,"like":55,"understand":50],
        ],
        "can": [
            "you":      ["please":85,"help":80,"send":70,"check":65,"tell":60,"give":55,"let":55,"get":50,"do":50],
            "we":       ["do":80,"go":75,"get":70,"meet":65,"talk":60,"have":55,"find":50,"make":45],
            "i":        ["help":85,"get":75,"do":65,"see":60,"send":55,"check":50,"find":45],
        ],
        "do": [
            "you":      ["want":90,"have":80,"know":75,"need":70,"think":65,"like":60,"remember":55,"see":50],
            "we":       ["need":80,"have":75,"want":70,"go":65,"do":60,"get":55,"know":50],
            "i":        ["need":80,"have":75,"want":70,"know":65,"do":60,"get":55],
        ],
        "how": [
            "are":      ["you":95,"things":75,"we":60,"the":50],
            "is":       ["it":85,"that":70,"the":60,"this":55,"everything":50],
            "do":       ["you":90,"we":75,"I":65],
            "can":      ["i":85,"we":75,"you":65],
        ],
        "what": [
            "do":       ["you":90,"we":80,"I":70],
            "are":      ["you":85,"we":75,"the":65,"your":60,"they":55],
            "is":       ["the":80,"your":70,"this":65,"that":60,"a":55,"going":50],
            "about":    ["the":75,"you":65,"this":60,"that":55,"a":50],
        ],
        "thank": [
            "you":      ["for":95,"so":70,"very":65],
        ],
        "thanks": [
            "for":      ["the":80,"your":75,"all":70,"letting":65,"helping":60,"sending":55,"being":50],
            "a":        ["lot":95],
        ],
        "let": [
            "me":       ["know":95,"check":80,"see":75,"try":70,"get":65,"ask":60,"find":55,"think":50],
            "you":      ["know":90,"be":70,"go":65,"down":55,"have":50],
            "us":       ["know":85,"go":75,"do":65,"get":60,"make":55,"see":50],
        ],
        "make": [
            "sure":     ["you":85,"that":80,"to":70,"it":65,"we":60,"I":55],
            "it":       ["work":80,"happen":70,"easier":65,"better":60,"possible":55],
            "a":        ["good":75,"great":70,"big":60,"small":55,"quick":50],
        ],
        "going": [
            "to":       ["be":90,"do":80,"get":75,"make":70,"go":65,"have":60,"need":55,"see":50,"try":50],
        ],
        "want": [
            "to":       ["go":85,"be":80,"get":75,"see":70,"do":65,"make":60,"have":55,"talk":50],
        ],
        "need": [
            "to":       ["be":85,"do":80,"get":75,"make":70,"go":65,"have":60,"check":55,"see":50,"talk":45],
        ],
        "sounds": [
            "good":     ["to":75,"I'll":70],
            "great":    ["to":75,"I'll":70],
            "like":     ["a":85,"fun":70,"the":60,"it":55],
        ],
        "looks": [
            "good":     ["to":75],
            "like":     ["a":85,"the":70,"it":60,"we":55,"you":50],
        ],
        "hope": [
            "you":      ["are":85,"have":75,"get":65,"feel":60,"enjoy":55,"had":50],
            "that":     ["helps":80,"works":70,"makes":65,"you":60,"it":55,"this":50],
            "it":       ["helps":80,"works":70,"goes":65,"makes":60],
        ],
        "i'm": [
            "going":    ["to":90],
            "not":      ["sure":85,"going":65,"a":60,"feeling":55,"able":50],
            "so":       ["sorry":80,"glad":70,"happy":65,"excited":60,"grateful":55],
            "really":   ["sorry":75,"glad":65,"happy":60,"excited":55,"grateful":50,"not":45],
            "a":        ["bit":80,"little":70,"big":55],
        ],
        "it's": [
            "not":      ["a":80,"the":70,"that":65,"as":60,"really":55,"going":50],
            "so":       ["good":80,"great":75,"much":70,"hard":65,"nice":60,"easy":55,"fun":50],
            "a":        ["good":80,"great":75,"lot":70,"bit":65,"long":60,"big":55,"little":50],
            "been":     ["a":80,"so":70,"really":65,"great":60,"good":55,"hard":50],
            "really":   ["good":80,"great":75,"hard":65,"nice":60,"easy":55,"fun":50],
        ],
        "that's": [
            "a":        ["good":85,"great":80,"lot":65,"really":60,"big":55,"little":50],
            "not":      ["a":80,"the":70,"what":65,"how":60,"right":55],
            "so":       ["good":75,"great":70,"nice":65,"true":60,"funny":55],
            "really":   ["good":75,"great":70,"nice":60,"interesting":55,"funny":50],
        ],
        "we": [
            "can":      ["do":85,"go":75,"get":70,"make":65,"talk":60,"meet":55,"have":50,"try":50],
            "should":   ["do":85,"go":75,"get":70,"meet":65,"talk":60,"have":55,"try":50],
            "need":     ["to":90,"a":65,"more":60,"some":55],
            "will":     ["be":85,"have":80,"get":70,"do":65,"make":60,"try":55],
            "are":      ["going":80,"not":70,"a":65,"the":60,"so":55,"working":50,"all":45],
        ],
        "let's": [
            "go":       ["to":80,"home":70,"out":65,"back":60],
            "do":       ["this":85,"it":75,"that":60,"something":55],
            "get":      ["started":80,"this":70,"together":65,"it":60],
            "make":     ["it":80,"this":70,"sure":65,"a":60],
            "talk":     ["about":85,"later":65,"soon":60,"tomorrow":55],
            "try":      ["to":80,"it":70,"again":65,"this":60],
        ],
        "i'll": [
            "be":       ["there":85,"right":70,"back":65,"in":60,"at":55,"with":50],
            "let":      ["you":95,"them":65,"her":55,"him":50],
            "get":      ["it":80,"back":70,"the":65,"that":60,"a":55,"started":50],
            "try":      ["to":85,"my":70,"it":60],
            "send":     ["you":85,"it":70,"the":65,"a":60,"them":55],
            "check":    ["it":80,"on":70,"the":65,"with":60,"that":55],
        ],
        "i've": [
            "been":     ["working":75,"thinking":70,"trying":65,"looking":60,"waiting":55,"meaning":50,"a":45],
            "got":      ["a":80,"the":70,"it":65,"some":60,"your":55],
            "already":  ["done":80,"sent":70,"checked":65,"seen":60,"got":55],
        ],
        "you're": [
            "right":    ["about":80,"I":65,"that":60],
            "welcome":  ["I":70,"anytime":65,"happy":60,"glad":55],
            "not":      ["going":70,"a":65,"the":60,"sure":55,"able":50],
            "going":    ["to":90],
        ],
        "there": [
            "is":       ["a":90,"the":80,"no":70,"nothing":65,"something":60,"an":55],
            "are":      ["a":85,"no":75,"some":65,"many":60,"few":55,"the":50],
        ],
        "this": [
            "is":       ["a":90,"the":85,"not":80,"so":70,"really":65,"great":60,"good":55,"amazing":50],
            "will":     ["be":85,"help":70,"make":65,"work":60,"take":55],
        ],
        "it": [
            "is":       ["a":90,"the":85,"not":80,"so":75,"very":70,"really":65,"just":60,"also":55],
            "was":      ["a":85,"the":80,"not":70,"so":65,"very":60,"really":55,"just":50],
            "will":     ["be":90,"help":70,"make":65,"take":60,"work":55],
        ],
        "so": [
            "much":     ["better":80,"more":70,"fun":65,"easier":60,"harder":55,"nicer":50],
            "many":     ["people":75,"things":70,"options":60,"times":55,"ways":50],
            "good":     ["to":80,"I":65,"that":60,"you":55],
        ],
        "really":  [
            "good":     ["idea":70,"point":65,"job":60,"work":55,"time":50],
            "sorry":    ["about":80,"for":70,"I":60,"that":55,"to":50],
            "glad":     ["you":80,"to":70,"we":60,"I":55,"it":50],
        ],
        "not": [
            "sure":     ["if":85,"what":75,"how":65,"about":60,"why":55,"where":50,"when":45],
            "going":    ["to":90],
        ],
    ]
}

// MARK: - HybridLanguageModel

final class HybridLanguageModel {

    private var personalBigrams:  [String: [String: Int]] = [:]
    private var personalTrigrams: [String: [String: [String: Int]]] = [:]

    private var wordsSinceLastSave = 0
    private let saveEvery = 100
    private let trigramMinTotal = 3  // need this many trigram observations to trust it

    // All access to the dictionaries goes through this serial queue: writes (learn)
    // and reads (predict) never overlap, and nothing runs on the main thread.
    private let queue = DispatchQueue(label: "tactl.languagemodel")

    private var fileURL: URL {
        AppGroup.containerURL.appendingPathComponent("language_model.json")
    }

    init() {
        // Load on the queue so construction never does a main-thread file read.
        // Enqueued before any predict()/learn(), so the first call sees loaded data.
        queue.async { [weak self] in self?.loadFromDisk() }
    }

    // MARK: - Learn (async — never blocks the keystroke)

    /// Call with the last few words (already split, in order) whenever a word is completed.
    func learn(recentWords: [String]) {
        queue.async { [weak self] in self?.applyLearn(recentWords) }
    }

    private func applyLearn(_ recentWords: [String]) {
        let words = recentWords
            .map { $0.lowercased().trimmingCharacters(in: CharacterSet.punctuationCharacters) }
            .filter { !$0.isEmpty && $0.unicodeScalars.count >= 2 && $0.unicodeScalars.count <= 25 }
        guard words.count >= 2 else { return }

        for i in 1..<words.count {
            personalBigrams[words[i-1], default: [:]][words[i], default: 0] += 1
        }
        for i in 2..<words.count {
            personalTrigrams[words[i-2], default: [:]
            ][words[i-1], default: [:]][words[i], default: 0] += 1
        }

        wordsSinceLastSave += 1
        if wordsSinceLastSave >= saveEvery {
            writeToDisk()
            wordsSinceLastSave = 0
        }
    }

    // MARK: - Predict (sync on the queue — caller is already off the main thread)

    /// Returns up to `count` next-word predictions given the last 1-2 complete words.
    func predict(previousWords: [String], count: Int = 3) -> [String] {
        queue.sync { computePredictions(previousWords: previousWords, count: count) }
    }

    private func computePredictions(previousWords: [String], count: Int) -> [String] {
        let words = previousWords
            .map { $0.lowercased().trimmingCharacters(in: CharacterSet.punctuationCharacters) }
            .filter { !$0.isEmpty }
        guard !words.isEmpty else { return [] }

        let p1 = words.last!
        let p2 = words.count >= 2 ? words[words.count - 2] : nil

        // Try trigram first
        if let p2 {
            let personal = personalTrigrams[p2]?[p1] ?? [:]
            let seed     = Seed.trigrams[p2]?[p1] ?? [:]
            let merged   = blended(seed: seed, personal: personal)
            if merged.values.reduce(0, +) >= trigramMinTotal {
                let top = Array(merged.sorted { $0.value > $1.value }.prefix(count).map { $0.key })
                if top.count >= 2 { return top }
            }
        }

        // Fall back to bigram
        let personal = personalBigrams[p1] ?? [:]
        let seed     = Seed.bigrams[p1] ?? [:]
        let merged   = blended(seed: seed, personal: personal)
        return Array(merged.sorted { $0.value > $1.value }.prefix(count).map { $0.key })
    }

    // Personal counts weighted 5× — personal patterns override seed after ~5 uses
    private func blended(seed: [String: Int], personal: [String: Int]) -> [String: Int] {
        var result = seed
        for (word, count) in personal {
            result[word, default: 0] += count * 5
        }
        return result
    }

    // MARK: - Persistence

    private struct Stored: Codable {
        var bigrams:  [String: [String: Int]]
        var trigrams: [String: [String: [String: Int]]]
    }

    /// Flush to disk. Sync so it completes before the extension may be suspended.
    func save() {
        queue.sync { writeToDisk() }
    }

    private func writeToDisk() {
        let stored = Stored(bigrams: personalBigrams, trigrams: personalTrigrams)
        guard let data = try? JSONEncoder().encode(stored) else { return }
        try? data.write(to: fileURL, options: [.atomic, .completeFileProtection])
    }

    private func loadFromDisk() {
        guard let data = try? Data(contentsOf: fileURL),
              let stored = try? JSONDecoder().decode(Stored.self, from: data)
        else { return }
        personalBigrams  = stored.bigrams
        personalTrigrams = stored.trigrams
    }
}
