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
        case appendSearchResults([PDFSearchResult])
        case endSearch
        case clearSearchText
        case selectSearchResult(PDFSearchResult)
    }

    private enum CancelID { case search }

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case let .updateSearchText(text):
            if text.isEmpty {
                return .run { send in
                    await send(.clearSearchText)
                }
            } else {
                state.searchText = text
                return .run { send in
                    await send(.beginSearch)
                }
                .debounce(id: CancelID.search, for: 0.5, scheduler: DispatchQueue.main)
                .cancellable(id: CancelID.search)
            }
        case .beginSearch:
            state.isSearching = true
            state.isSearchResultsShown = true
            state.searchResults = []
            return searchEffect(for: state.searchText, in: state.pdfDocument)
                .cancellable(id: CancelID.search)
        case let .appendSearchResults(results):
            state.searchResults += results
            return .none
        case .endSearch:
            state.isSearching = false
            return .none
        case .clearSearchText:
            state.isSearchResultsShown = false
            state.isSearching = false
            state.searchText = ""
            state.searchResults = []
            return .cancel(id: CancelID.search)
        case let .selectSearchResult(result):
            state.currentPageIndex = result.pageIndex
            return .cancel(id: CancelID.search)
        }
    }

    private func searchEffect(for query: String, in document: PDFDocument?) -> Effect<Action> {
        Effect.run { send in
            guard let document else {
                await send(.endSearch)
                return
            }

            var startTime = Date()

            var bufferedResults: [PDFSearchResult] = []

            for i in 0 ..< document.pageCount {
                guard let page = document.page(at: i) else { continue }

                if page.string?.contains(query) ?? false {
                    let thumbnail = page.thumbnail(of: CGSize(width: 400, height: 600), for: .cropBox)
                    bufferedResults.append(PDFSearchResult(pageIndex: i, thumbnail: thumbnail))
                }

                let currentTime = Date()
                if currentTime.timeIntervalSince(startTime) >= 1.0 {
                    if !bufferedResults.isEmpty {
                        await send(.appendSearchResults(bufferedResults))
                        bufferedResults.removeAll()
                    }
                    startTime = currentTime
                }
            }

            await send(.appendSearchResults(bufferedResults))
            await send(.endSearch)
        }
    }
}
