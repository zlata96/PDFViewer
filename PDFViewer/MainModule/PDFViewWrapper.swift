// PDFViewWrapper.swift
// PDFViewer. Created by Zlata Guseva.

import PDFKit
import SwiftUI

struct PDFViewWrapper: UIViewRepresentable {
    var pdfDocument: PDFDocument?
    @Binding var currentPageIndex: Int?

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.backgroundColor = .clear
        pdfView.autoScales = true
        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        if pdfView.document != pdfDocument {
            pdfView.document = pdfDocument
        }

        if let pageIndex = currentPageIndex, let page = pdfDocument?.page(at: pageIndex) {
            DispatchQueue.main.async {
                pdfView.go(to: page)
            }
        }
    }
}
