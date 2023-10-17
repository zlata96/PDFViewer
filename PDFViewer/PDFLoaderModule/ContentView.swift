// ContentView.swift
// PDFViewer. Created by Zlata Guseva.

import ComposableArchitecture
import PDFKit
import SwiftUI

struct AppReducer: Reducer {
    struct State: Equatable {
        var pdfDocument: PDFDocument?
        var pdfDocumentIsLoading = false
        var pdfDocumentIsLoaded = false
        var currentPageIndex: Int?

        @PresentationState var searchingSheetState: SearchReducer.State?
    }

    enum Action: Equatable {
        case pdfLoadingStarted
        case pdfLoadingCompleted(PDFDocument?)
        case pdfLoadingFailed
        case searchButtonTapped

        case searchSheet(PresentationAction<SearchReducer.Action>)
    }

    var body: some ReducerOf<AppReducer> {
        Reduce { state, action in
            switch action {
            case .pdfLoadingStarted:
                state.pdfDocumentIsLoading = true
                return Effect.run { send in
                    try await Task.sleep(nanoseconds: 1_000_000_000)
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
                state.pdfDocumentIsLoaded = true
                state.pdfDocument = pdfDocument
                return .none
            case .pdfLoadingFailed:
                state.pdfDocumentIsLoading = false
                return .none
            case .searchButtonTapped:
                state.searchingSheetState = SearchReducer.State(pdfDocument: state.pdfDocument)
                return .none
            case let .searchSheet(.presented(.selectSearchResult(pdfSearchResult))):
                state.searchingSheetState = nil
                state.currentPageIndex = pdfSearchResult.pageIndex
                return .none
            case .searchSheet:
                return .none
            }
        }
        .ifLet(\.$searchingSheetState, action: /Action.searchSheet) {
            SearchReducer()
        }
    }
}

struct ContentView: View {
    let store: StoreOf<AppReducer>

    var body: some View {
        NavigationView {
            WithViewStore(store, observe: { $0 }) { viewStore in
                ZStack {
                    pdfView
                    if !viewStore.pdfDocumentIsLoaded {
                        HStack {
                            Button("Загрузить PDF документ") {
                                viewStore.send(.pdfLoadingStarted)
                            }
                            .padding()
                            if viewStore.pdfDocumentIsLoading {
                                ProgressView()
                            }
                        }
                    }
                    if viewStore.pdfDocumentIsLoaded {
                        VStack {
                            Spacer()
                            Button(action: {
                                viewStore.send(.searchButtonTapped)
                            }) {
                                Text("Поиск")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.green)
                                    .cornerRadius(10)
                            }
                            .padding()
                        }
                        .sheet(store: store.scope(state: \.$searchingSheetState, action: AppReducer.Action.searchSheet)) { store in
                            SearchContentView(store: store)
                        }
                    }
                }
                .navigationTitle("PDFViewer")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }

    var pdfView: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            PDFViewWrapper(
                pdfDocument: viewStore.pdfDocument,
                currentPageIndex: viewStore.binding(
                    get: { $0.currentPageIndex },
                    send: AppReducer.Action.searchSheet(.dismiss)
                )
            )
            .ignoresSafeArea()
        }
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
