import SwiftUI

struct SettingsView: View {
    @StateObject private var store = SettingsStore()

    var body: some View {
        NavigationStack {
            Form {
                onboardingSection
                heightSection
                longPressSection
                cursorSection
                layoutSection
                clipboardSection
                hapticsSection
                soundSection
                themeSection
                dictionarySection
                aboutSection
            }
            .navigationTitle("Tactl Keyboard")
        }
        .onChange(of: store.current.keyboardHeight) { store.save() }
        .onChange(of: store.current.longPressDuration) { store.save() }
        .onChange(of: store.current.spaceCursorEnabled) { store.save() }
        .onChange(of: store.current.spaceCursorVerticalEnabled) { store.save() }
        .onChange(of: store.current.numberRowEnabled) { store.save() }
        .onChange(of: store.current.clipboardEnabled) { store.save() }
        .onChange(of: store.current.hapticIntensity) { store.save() }
        .onChange(of: store.current.soundEnabled) { store.save() }
        .onChange(of: store.current.theme) { store.save() }
    }

    @ViewBuilder
    private var onboardingSection: some View {
        if !store.current.onboardingDismissed {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Enable Tactl").font(.headline)
                    Text("Settings → General → Keyboard → Keyboards → Add New Keyboard → Tactl → Allow Full Access")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button("Got it") {
                        store.current.onboardingDismissed = true
                        store.save()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.vertical, 4)
            }
        }
    }

    private var heightSection: some View {
        Section("Keyboard Height") {
            VStack(alignment: .leading) {
                HStack {
                    Text("Height")
                    Spacer()
                    Text("\(Int(store.current.keyboardHeight)) pt")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                Slider(value: $store.current.keyboardHeight, in: 200...340, step: 1)
            }
        }
    }

    private var longPressSection: some View {
        Section("Long-Press Duration") {
            VStack(alignment: .leading) {
                HStack {
                    Text("Duration")
                    Spacer()
                    Text("\(Int(store.current.longPressDuration * 1000)) ms")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                Slider(value: $store.current.longPressDuration, in: 0.1...0.6, step: 0.01)
            }
        }
    }

    private var cursorSection: some View {
        Section("Spacebar Cursor Drag") {
            Toggle("Enable cursor drag", isOn: $store.current.spaceCursorEnabled)
            if store.current.spaceCursorEnabled {
                Toggle("Vertical drag (line navigation)", isOn: $store.current.spaceCursorVerticalEnabled)
            }
        }
    }

    private var layoutSection: some View {
        Section("Layout") {
            Toggle("Number row", isOn: $store.current.numberRowEnabled)
        }
    }

    private var clipboardSection: some View {
        Section("Clipboard History") {
            Toggle("Enable clipboard history", isOn: $store.current.clipboardEnabled)
            if store.current.clipboardEnabled {
                Button("Clear clipboard history", role: .destructive) {
                    store.clearClipboard()
                }
            }
        }
    }

    private var hapticsSection: some View {
        Section("Haptics") {
            Picker("Intensity", selection: $store.current.hapticIntensity) {
                ForEach(HapticIntensity.allCases, id: \.self) { intensity in
                    Text(intensity.displayName).tag(intensity)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var soundSection: some View {
        Section("Sound") {
            Toggle("Key click sound", isOn: $store.current.soundEnabled)
            Text("iOS also requires Settings → Sounds & Haptics → Keyboard Feedback → Sound to be ON.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @State private var dictionaryWords: [String] = PersonalDictionary.load()
    @State private var newWord: String = ""

    private var dictionarySection: some View {
        Section("Personal Dictionary") {
            HStack {
                TextField("Add word", text: $newWord)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button("Add") {
                    if PersonalDictionary.add(newWord) {
                        newWord = ""
                        dictionaryWords = PersonalDictionary.load()
                    }
                }
                .disabled(newWord.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            if dictionaryWords.isEmpty {
                Text("No learned words yet. Tap the leftmost chip in the keyboard toolbar to teach a word.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(dictionaryWords, id: \.self) { word in
                    HStack {
                        Text(word)
                        Spacer()
                        Button(role: .destructive) {
                            PersonalDictionary.remove(word)
                            dictionaryWords = PersonalDictionary.load()
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }
        }
        .onAppear { dictionaryWords = PersonalDictionary.load() }
    }

    private var themeSection: some View {
        Section("Theme") {
            Picker("Theme", selection: $store.current.theme) {
                ForEach(ThemeMode.allCases, id: \.self) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    SettingsView()
}
