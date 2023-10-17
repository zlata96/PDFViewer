// MainReducer.swift
// PDFViewer. Created by Zlata Guseva.

import ComposableArchitecture
import PDFKit

struct MainReducer: Reducer {
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

    var body: some ReducerOf<MainReducer> {
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
