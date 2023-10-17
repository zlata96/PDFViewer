// SearchReducer.swift
// PDFViewer. Created by Zlata Guseva.

import ComposableArchitecture
import Foundation
import PDFKit
import SwiftUI

struct SearchReducer: Reducer {
    struct State: Equatable {
        var pdfDocument: PDFDocument?
        var currentPageIndex: Int?

        var searchText: String = ""
        var searchResults: [PDFSearchResult] = []
        var isSearching = false
        var isSearchResultsShown = false
    }

    enum Action: Equatable {
        case updateSearchText(String)
        case beginSearch
        case appendSearchResult(PDFSearchResult)
        case endSearch
        case clearSearchText

        case selectSearchResult(PDFSearchResult)
    }

    struct PDFSearchResult: Equatable, Identifiable {
        let id = UUID()
        let pageIndex: Int
        let thumbnail: UIImage?
    }

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
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
            state.searchResults = []
            return .none
        case let .selectSearchResult(result):
            state.searchText = ""
            state.isSearching = false
            state.isSearchResultsShown = false
            state.currentPageIndex = result.pageIndex
            return .none
        }
    }

    func searchEffect(for query: String, in document: PDFDocument?) -> Effect<Action> {
        Effect.run { send in
            guard let document else {
                await send(.endSearch)
                return
            }

            // try await Task.sleep(nanoseconds: 1_000_000_000)

            for i in 0 ..< document.pageCount {
                guard let page = document.page(at: i) else { continue }

                if page.string?.contains(query) ?? false {
                    let thumbnail = page.thumbnail(of: CGSize(width: 400, height: 600), for: .cropBox)
                    await send(.appendSearchResult(PDFSearchResult(pageIndex: i, thumbnail: thumbnail)))
                }
            }

            await send(.endSearch)
        }
    }
}
