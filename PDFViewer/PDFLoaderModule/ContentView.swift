// ContentView.swift
// PDFViewer. Created by Zlata Guseva.

import ComposableArchitecture
import PDFKit
import SwiftUI

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
                                HStack {
                                    Image(systemName: "xmark.circle.fill")
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
