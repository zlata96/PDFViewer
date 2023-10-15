// PDFViewWrapper.swift
// PDFViewer. Created by Zlata Guseva.

import PDFKit
import SwiftUI

struct PDFViewWrapper: UIViewRepresentable {
    var pdfDocument: PDFDocument?

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = pdfDocument
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        uiView.document = pdfDocument
    }
}
