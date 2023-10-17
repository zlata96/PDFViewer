// MainView.swift
// PDFViewer. Created by Zlata Guseva.

import ComposableArchitecture
import PDFKit
import SwiftUI

struct MainView: View {
    let store: StoreOf<MainReducer>

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            NavigationView {
                ZStack {
                    if viewStore.pdfDocumentIsLoaded {
                        pdfView
                        searchButtonView
                    } else {
                        loadButtonView
                    }
                }
                .navigationTitle("PDFViewer")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .sheet(store: store.scope(state: \.$searchingSheetState, action: MainReducer.Action.searchSheet)) { store in
            SearchView(store: store)
        }
    }

    private var pdfView: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            PDFViewWrapper(
                pdfDocument: viewStore.pdfDocument,
                currentPageIndex: viewStore.binding(
                    get: { $0.currentPageIndex },
                    send: MainReducer.Action.searchSheet(.dismiss)
                )
            )
        }
    }

    private var loadButtonView: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
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

    private var searchButtonView: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack {
                Spacer()
                Button(action: {
                    viewStore.send(.searchButtonTapped)
                }) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white)
                        Text("Поиск")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .padding()
                }
                .background(Color.gray)
                .cornerRadius(16)
                .padding()
            }
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView(
            store: Store(initialState: MainReducer.State()) {
                MainReducer()
            }
        )
    }
}
