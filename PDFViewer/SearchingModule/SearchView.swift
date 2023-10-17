// SearchView.swift
// PDFViewer. Created by Zlata Guseva.

import ComposableArchitecture
import PDFKit
import SwiftUI

struct SearchView: View {
    let store: StoreOf<SearchReducer>

    var body: some View {
        NavigationView {
            WithViewStore(store, observe: { $0 }) { viewStore in
                ZStack {
                    VStack {
                        searchBarView
                        searchListView
                    }
                }
            }
            .navigationTitle("Поиск по документу")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    var searchBarView: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                    TextField(
                        "Введите текст",
                        text: viewStore.binding(
                            get: \.searchText,
                            send: SearchReducer.Action.updateSearchText
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
                HStack {
                    if viewStore.isSearchResultsShown {
                        Text("Найдено \(viewStore.searchResults.count) совпадений")
                            .font(.caption)
                    }

                    if viewStore.isSearching {
                        ProgressView()
                            .padding(.leading, 8)
                    }
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
                                .font(.caption)
                        }
                        .shadow(radius: 6)
                        .padding(.horizontal)
                        .onTapGesture {
                            DispatchQueue.main.async {
                                viewStore.send(.selectSearchResult(result))
                            }
                        }
                    }
                }
                .padding()
            }
        }
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView(
            store: Store(initialState: SearchReducer.State()) {
                SearchReducer()
            }
        )
    }
}
