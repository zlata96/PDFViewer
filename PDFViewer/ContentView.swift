// ContentView.swift
// PDFViewer. Created by Zlata Guseva.

import ComposableArchitecture
import PDFKit
import SwiftUI

struct AppReducer: Reducer {
    struct State: Equatable {
        var pdfDocument: PDFDocument?
        var pdfDocumentIsLoading = false
    }

    enum Action: Equatable {
        case pdfLoadingStarted
        case pdfLoadingCompleted(PDFDocument?)
        case pdfLoadingFailed
    }

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .pdfLoadingStarted:
            state.pdfDocumentIsLoading = true
            return Effect.run { send in
                if let url = Bundle.main.url(forResource: "test", withExtension: "pdf"),
                   let pdfDocument = PDFDocument(url: url)
                {
                    await send(.pdfLoadingCompleted(pdfDocument))
                } else {
                    await send(.pdfLoadingFailed)
                }
            }
        case let .pdfLoadingCompleted(pdfDocument):
            state.pdfDocumentIsLoading = false
            state.pdfDocument = pdfDocument
            return .none
        case .pdfLoadingFailed:
            state.pdfDocumentIsLoading = false
            return .none
        }
    }
}

struct ContentView: View {
    let store: StoreOf<AppReducer>

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            ZStack {
                VStack {
                    searchView
                    HStack {
                        Button("Загрузить PDF документ") {
                            viewStore.send(.pdfLoadingStarted)
                        }
                        .padding()
                        if viewStore.pdfDocumentIsLoading {
                            ProgressView()
                        }
                    }
                    PDFViewWrapper(pdfDocument: viewStore.pdfDocument)
                }
            }
            .sheet(isPresented: .constant(false)) {
//                SearchResultsView(store: self.store)
            }
        }
    }

    var searchView: some View {
        HStack {
            Image(systemName: "magnifyingglass")
            TextField("Placeholder", text: .constant(""))
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.none)
                .disableAutocorrection(true)
        }
        .padding(.horizontal, 16)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(
            store: Store(initialState: AppReducer.State()) {
                AppReducer()
            }
        )
    }
}
