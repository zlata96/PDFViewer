// PDFViewerApp.swift
// PDFViewer. Created by Zlata Guseva.

import ComposableArchitecture
import SwiftUI

@main
struct PDFViewerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(store: Store(initialState: AppReducer.State()) {
                AppReducer()
                    ._printChanges()
            }
            )
        }
    }
}
