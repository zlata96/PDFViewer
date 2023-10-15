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
        var currentPageIndex: Int? = nil

        var searchText: String = ""
        var searchResults: [PDFSearchResult] = []
        var isSearching = false
        var isSearchResultsShown = false
    }

    enum Action: Equatable {
        case pdfLoadingStarted
        case pdfLoadingCompleted(PDFDocument?)
        case pdfLoadingFailed
        case updateSearchText(String)
        case beginSearch
        case appendSearchResult(PDFSearchResult)
        case endSearch
        case clearSearchText
        case selectSearchResult(PDFSearchResult)
        case updateCurrentPageIndex(Int?)
    }

    struct PDFSearchResult: Equatable, Identifiable {
        let id = UUID()
        let pageIndex: Int
        let thumbnail: UIImage?
    }

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
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
        case let .updateSearchText(text):
            if text.isEmpty {
                return .none
            } else {
                state.isSearchResultsShown = true
                state.searchText = text
                return .run { send in
                    await send(.beginSearch)
                }
                .cancellable(id: "search")
                .debounce(id: "search", for: 0.3, scheduler: DispatchQueue.main)
            }
        case .beginSearch:
            state.isSearching = true
            state.searchResults = []
            return searchEffect(for: state.searchText, in: state.pdfDocument)
        case let .appendSearchResult(result):
            state.searchResults.append(result)
            return .none
        case .endSearch:
            state.isSearching = false
            return .none
        case .clearSearchText:
            state.isSearchResultsShown = false
            state.searchText = ""
            return .none
        case let .selectSearchResult(result):
            state.searchText = ""
            state.isSearching = false
            state.isSearchResultsShown = false
            state.currentPageIndex = result.pageIndex
            return .none
        case let .updateCurrentPageIndex(index):
            state.currentPageIndex = index
            return .none
        }
    }

    func searchEffect(for query: String, in document: PDFDocument?) -> Effect<Action> {
        Effect.run { send in
            guard let document else {
                await send(.endSearch)
                return
            }

            for i in 0 ..< document.pageCount {
                guard let page = document.page(at: i) else { continue }

                if page.string?.contains(query) ?? false {
                    let thumbnail = page.thumbnail(of: CGSize(width: 40, height: 60), for: .cropBox)
                    await send(.appendSearchResult(PDFSearchResult(pageIndex: i, thumbnail: thumbnail)))
                }
                // TODO:
                // try await Task.sleep(nanoseconds: 1_000_000_000)
            }

            await send(.endSearch)
        }
    }
}

struct ContentView: View {
    let store: StoreOf<AppReducer>

    var body: some View {
        NavigationView {
            WithViewStore(store, observe: { $0 }) { viewStore in
                ZStack {
                    VStack {
                        searchBarView
                        if viewStore.isSearchResultsShown {
                            searchListView
                        } else {
                            pdfView
                        }
                    }
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
                }
            }
            .navigationTitle("PDFViewer")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    var pdfView: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            PDFViewWrapper(
                pdfDocument: viewStore.pdfDocument,
                currentPageIndex: viewStore.binding(
                    get: { $0.currentPageIndex },
                    send: AppReducer.Action.updateCurrentPageIndex
                )
            )
            .ignoresSafeArea()
        }
    }

    var searchBarView: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                    TextField(
                        "Placeholder",
                        text: viewStore.binding(
                            get: \.searchText,
                            send: AppReducer.Action.updateSearchText
                        )
                    )
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .overlay(
                        Group {
                            if !viewStore.searchText.isEmpty {
                                Button(action: {
                                    viewStore.send(.clearSearchText)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                        .padding(.trailing, 8)
                                }
                            }
                        },
                        alignment: .trailing
                    )
                }
                if viewStore.isSearchResultsShown {
                    Text("Найдено \(viewStore.searchResults.count) совпадений")
                        .font(.caption)
                }
            }
            .padding(.horizontal)
        }
    }

    var searchListView: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            ScrollView {
                LazyVGrid(
                    columns: .init(repeating: GridItem(.flexible()), count: 3),
                    spacing: 16
                ) {
                    ForEach(viewStore.searchResults) { result in
                        VStack {
                            Image(uiImage: result.thumbnail ?? UIImage())
                                .resizable()
                                .frame(width: 80, height: 120)
                            Text("стр. \(result.pageIndex + 1)")
                        }
                        .padding(.horizontal)
                        .onTapGesture {
                            DispatchQueue.main.async {
                                viewStore.send(.selectSearchResult(result))
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
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
