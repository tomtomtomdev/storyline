//
//  ContentView.swift
//  storyline
//
//  Created by Tommy Yohanes on 12/12/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var audiobooks: [Audiobook]
    @State private var selectedTab = 0
    @State private var playbackManager: PlaybackManager?
    @State private var playerViewModel: PlayerViewModel?

    var body: some View {
        TabView(selection: $selectedTab) {
            // Library Tab
            LibraryView(playbackManager: playbackManager)
                .tabItem {
                    Label("Library", systemImage: "books.vertical")
                }
                .tag(0)

            // Add Tab
            AddAudiobookView()
                .tabItem {
                    Label("Add", systemImage: "plus.circle")
                }
                .tag(1)

            // Settings Tab
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(2)
        }
        .tint(Color.themePrimary)
        .onAppear {
            Task {
                // Initialize playback manager
                if playbackManager == nil {
                    playbackManager = PlaybackManager()
                    playerViewModel = PlayerViewModel(
                        playbackManager: playbackManager!,
                        modelContext: modelContext
                    )

                    // Create sample audiobooks if library is empty
                    if audiobooks.isEmpty {
                        await createSampleAudiobooks()
                    }
                }
            }
        }
    }

    // MARK: - Private Methods

    /// Creates sample audiobooks for testing
    private func createSampleAudiobooks() async {
        // Create sample audio file
        guard let audioURL = AudioFileManager.createSampleAudioFile() else {
            print("Failed to create sample audio file")
            return
        }

        // Create sample audiobooks
        let sampleBooks = [
            Audiobook(
                title: "The Art of Swift Development",
                author: "Apple Education Team",
                narrator: "Professional Narrator",
                duration: 30, // 30 seconds for sample
                audioFileURL: audioURL,
                tags: ["Education", "Programming", "Favorites"]
            ),
            Audiobook(
                title: "Mystery at Midnight",
                author: "Jane Doe",
                narrator: "John Smith",
                duration: 30,
                audioFileURL: audioURL,
                tags: ["Fiction", "Mystery"]
            ),
            Audiobook(
                title: "History of Technology",
                author: "Dr. Robert Johnson",
                narrator: "Emma Wilson",
                duration: 30,
                audioFileURL: audioURL,
                tags: ["Non-fiction", "History", "Technology"]
            )
        ]

        // Insert into SwiftData
        for book in sampleBooks {
            modelContext.insert(book)
        }

        do {
            try modelContext.save()
        } catch {
            print("Failed to save sample audiobooks: \(error)")
        }
    }
}

// MARK: - Library View

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var audiobooks: [Audiobook]
    @State private var searchText = ""
    @State private var viewLayout: ViewLayoutOption = .grid
    @State private var sortOrder: SortOption = .dateAdded
    @State private var selectedAudiobook: Audiobook?
    @State private var showingPlayer = false

    let playbackManager: PlaybackManager?

    var filteredAudiobooks: [Audiobook] {
        var filtered = audiobooks

        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { book in
                book.title.localizedCaseInsensitiveContains(searchText) ||
                book.author.localizedCaseInsensitiveContains(searchText) ||
                book.narrator?.localizedCaseInsensitiveContains(searchText) == true
            }
        }

        // Sort
        switch sortOrder {
        case .title:
            filtered.sort { $0.title.localizedCompare($1.title) == .orderedAscending }
        case .author:
            filtered.sort { $0.author.localizedCompare($1.author) == .orderedAscending }
        case .dateAdded:
            filtered.sort { $0.dateAdded > $1.dateAdded }
        case .lastPlayed:
            filtered.sort { ($0.lastPlayedDate ?? Date.distantPast) > ($1.lastPlayedDate ?? Date.distantPast) }
        case .progress:
            filtered.sort { $0.progress < $1.progress }
        case .duration:
            filtered.sort { $0.duration < $1.duration }
        }

        return filtered
    }

    var body: some View {
        NavigationStack {
            Group {
                if filteredAudiobooks.isEmpty {
                    EmptyLibraryView()
                } else {
                    ScrollView {
                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible()), count: viewLayout == .grid ? 2 : 1),
                            spacing: UIConstants.standardPadding
                        ) {
                            ForEach(filteredAudiobooks) { audiobook in
                                AudiobookCard(
                                    audiobook: audiobook,
                                    playbackManager: playbackManager,
                                    onTap: {
                                        selectedAudiobook = audiobook
                                        showingPlayer = true
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, UIConstants.standardPadding)
                    }
                }
            }
            .navigationTitle("My Library")
            .searchable(text: $searchText, prompt: "Search audiobooks...")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Picker("View Layout", selection: $viewLayout) {
                            ForEach(ViewLayoutOption.allCases) { option in
                                Label(option.rawValue, systemImage: option.systemImage)
                            }
                        }
                        .pickerStyle(.menu)

                        Picker("Sort By", selection: $sortOrder) {
                            ForEach(SortOption.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                        .pickerStyle(.menu)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingPlayer) {
                if let audiobook = selectedAudiobook {
                    PlayerView(audiobook: audiobook, playbackManager: playbackManager)
                }
            }
        }
    }
}

// MARK: - Empty Library View

struct EmptyLibraryView: View {
    var body: some View {
        VStack(spacing: UIConstants.largePadding) {
            Image(systemName: "books.vertical.fill")
                .font(.system(size: 80))
                .foregroundColor(.secondary)

            VStack(spacing: UIConstants.smallPadding) {
                Text("No Audiobooks Yet")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Add your first audiobook to get started")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: {
                // TODO: Navigate to add audiobook
            }) {
                Text("Add Audiobook")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, UIConstants.largePadding)
                    .padding(.vertical, UIConstants.standardPadding)
                    .background(Color.themePrimary)
                    .cornerRadius(UIConstants.buttonCornerRadius)
            }
            .buttonStyle(.plain)
        }
        .padding(UIConstants.largePadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.emptyStateGradient)
    }
}

// MARK: - Add Audiobook View (Placeholder)

struct AddAudiobookView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: UIConstants.largePadding) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.secondary)

                Text("Add Audiobook")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Import audiobooks from your device or download from URLs")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, UIConstants.largePadding)

                Text("This feature will be implemented in Phase 2")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .italic()
            }
            .padding(UIConstants.largePadding)
            .navigationTitle("Add Audiobook")
        }
    }
}

// MARK: - Settings View (Placeholder)

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            Form {
                Section("Playback") {
                    // TODO: Add playback settings
                    Text("Playback settings will be implemented in Phase 2")
                }

                Section("Appearance") {
                    // TODO: Add appearance settings
                    Text("Appearance settings will be implemented in Phase 2")
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(AppConstants.appVersion)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Audiobook.self, inMemory: true)
}
