//
//  PDFRenderer.swift
//  FlowLedger
//
//  Created by Pankaj Gaikar on 02/11/25.
//

import Foundation
import SwiftUI
import UIKit
import PDFKit

enum PDFTemplate: String {
    case clean = "clean"
    case noir = "noir"
}

@MainActor
class PDFRenderer {
    static let shared = PDFRenderer()
    
    private init() {}
    
    func renderPDF(for invoice: Invoice, template: PDFTemplate = .clean) -> URL? {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        let pdfMetaData = [
            kCGPDFContextCreator: "FlowLedger",
            kCGPDFContextAuthor: invoice.client?.name ?? "Unknown",
            kCGPDFContextTitle: invoice.invoiceNumber
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.5 * 72.0 // US Letter width
        let pageHeight = 11 * 72.0 // US Letter height
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            var yPosition: CGFloat = 24
            
            // Header
            let headerRect = CGRect(x: 24, y: yPosition, width: pageWidth - 48, height: 60)
            if template == .noir {
                UIColor.black.setFill()
                UIRectFill(headerRect)
            }
            
            // Invoice Number
            let invoiceNumberText = "Invoice: \(invoice.invoiceNumber)"
            invoiceNumberText.draw(at: CGPoint(x: 24, y: yPosition + 10), withAttributes: [
                .font: UIFont.boldSystemFont(ofSize: 24),
                .foregroundColor: template == .noir ? UIColor.white : UIColor.black
            ])
            
            yPosition += 70
            
            // Client Info
            if let client = invoice.client {
                let clientInfo = """
                Bill To:
                \(client.name)
                \(client.email ?? "")
                \(client.address ?? "")
                """
                clientInfo.draw(in: CGRect(x: 24, y: yPosition, width: pageWidth - 48, height: 80), withAttributes: [
                    .font: UIFont.systemFont(ofSize: 12),
                    .foregroundColor: template == .noir ? UIColor.white : UIColor.black
                ])
            }
            
            yPosition += 90
            
            // Dates
            let datesText = """
            Issued: \(formatter.string(from: invoice.issuedDate))
            \(invoice.dueDate != nil ? "Due: \(formatter.string(from: invoice.dueDate!))" : "")
            """
            datesText.draw(in: CGRect(x: pageWidth - 200, y: yPosition - 90, width: 176, height: 50), withAttributes: [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: template == .noir ? UIColor.white : UIColor.black
            ])
            
            // Line Items Table
            let tableY = yPosition
            var currentY = tableY
            
            // Table Header
            let headerAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 12),
                .foregroundColor: template == .noir ? UIColor.white : UIColor.black
            ]
            
            "Description".draw(at: CGPoint(x: 24, y: currentY), withAttributes: headerAttributes)
            "Qty".draw(at: CGPoint(x: pageWidth / 2, y: currentY), withAttributes: headerAttributes)
            "Price".draw(at: CGPoint(x: pageWidth / 2 + 80, y: currentY), withAttributes: headerAttributes)
            "Total".draw(at: CGPoint(x: pageWidth - 100, y: currentY), withAttributes: headerAttributes)
            
            currentY += 30
            
            // Draw line
            UIColor.gray.setStroke()
            let linePath = UIBezierPath()
            linePath.move(to: CGPoint(x: 24, y: currentY))
            linePath.addLine(to: CGPoint(x: pageWidth - 24, y: currentY))
            linePath.stroke()
            
            currentY += 15
            
            // Line Items
            let itemAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11),
                .foregroundColor: template == .noir ? UIColor.white : UIColor.black
            ]
            
            for item in invoice.lineItems {
                item.description.draw(at: CGPoint(x: 24, y: currentY), withAttributes: itemAttributes)
                "\(item.quantity)".draw(at: CGPoint(x: pageWidth / 2, y: currentY), withAttributes: itemAttributes)
                "₹\(item.unitPrice)".draw(at: CGPoint(x: pageWidth / 2 + 80, y: currentY), withAttributes: itemAttributes)
                "₹\(item.total)".draw(at: CGPoint(x: pageWidth - 100, y: currentY), withAttributes: itemAttributes)
                currentY += 25
                
                if currentY > pageHeight - 200 {
                    context.beginPage()
                    currentY = 24
                }
            }
            
            currentY += 20
            
            // Totals
            let totalsX = pageWidth - 200
            let totalAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: template == .noir ? UIColor.white : UIColor.black
            ]
            
            "Subtotal: ₹\(invoice.subtotal)".draw(at: CGPoint(x: totalsX, y: currentY), withAttributes: totalAttributes)
            currentY += 20
            
            if invoice.discount > 0 {
                "Discount: -₹\(invoice.discount)".draw(at: CGPoint(x: totalsX, y: currentY), withAttributes: totalAttributes)
                currentY += 20
            }
            
            if invoice.taxRate > 0 {
                let tax = (invoice.subtotal - invoice.discount) * invoice.taxRate
                "Tax (\(invoice.taxRate * 100)%): ₹\(tax)".draw(at: CGPoint(x: totalsX, y: currentY), withAttributes: totalAttributes)
                currentY += 20
            }
            
            let boldTotalAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 16),
                .foregroundColor: template == .noir ? UIColor.white : UIColor.black
            ]
            "Total: ₹\(invoice.total)".draw(at: CGPoint(x: totalsX, y: currentY), withAttributes: boldTotalAttributes)
            
            // Notes
            if let notes = invoice.notes, !notes.isEmpty {
                currentY += 50
                notes.draw(in: CGRect(x: 24, y: currentY, width: pageWidth - 48, height: 100), withAttributes: [
                    .font: UIFont.systemFont(ofSize: 10),
                    .foregroundColor: template == .noir ? UIColor.white : UIColor.black
                ])
            }
        }
        
        // Save to temporary file
        let fileName = "\(invoice.invoiceNumber).pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: tempURL)
            return tempURL
        } catch {
            AnalyticsService.shared.logNonFatalError(error, context: "pdf_render")
            return nil
        }
    }
}

