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

    var body: some View {
        TabView(selection: $selectedTab) {
            // Library Tab
            LibraryView()
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
    }
}

// MARK: - Library View

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var audiobooks: [Audiobook]
    @State private var searchText = ""
    @State private var viewLayout: ViewLayoutOption = .grid
    @State private var sortOrder: SortOption = .dateAdded

    var filteredAudiobooks: [Audiobook] {
        // TODO: Implement filtering and sorting
        audiobooks
    }

    var body: some View {
        NavigationStack {
            Group {
                if filteredAudiobooks.isEmpty {
                    EmptyLibraryView()
                } else {
                    // TODO: Implement library content
                    Text("Library content will be implemented")
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
