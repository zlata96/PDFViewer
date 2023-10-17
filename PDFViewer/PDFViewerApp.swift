// PDFViewerApp.swift
// PDFViewer. Created by Zlata Guseva.

import ComposableArchitecture
import SwiftUI

@main
struct PDFViewerApp: App {
    var body: some Scene {
        WindowGroup {
            MainView(store: Store(initialState: MainReducer.State()) {
                MainReducer()
                    ._printChanges()
            }
            )
        }
    }
}
