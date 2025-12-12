//
//  StorylineApp.swift
//  storyline
//
//  Created by Tommy Yohanes on 12/12/25.
//

import SwiftUI
import SwiftData

@main
struct StorylineApp: App {
    /// Shared model container for SwiftData
    let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainer(
                for: Audiobook.self,
                Chapter.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: false)
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
        }
    }
}
