// PDFSearchResult.swift
// PDFViewer. Created by Zlata Guseva.

import UIKit

struct PDFSearchResult: Equatable, Identifiable {
    let id = UUID()
    let pageIndex: Int
    let thumbnail: UIImage?
}
