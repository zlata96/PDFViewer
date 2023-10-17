// MainView.swift
// PDFViewer. Created by Zlata Guseva.

import ComposableArchitecture
import PDFKit
import SwiftUI

struct MainView: View {
    let store: StoreOf<MainReducer>

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
                        .sheet(store: store.scope(state: \.$searchingSheetState, action: MainReducer.Action.searchSheet)) { store in
                            SearchView(store: store)
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
                    send: MainReducer.Action.searchSheet(.dismiss)
                )
            )
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
