//
//  CurrencyText.swift
//  FlowLedger
//
//  Created by Pankaj Gaikar on 02/11/25.
//

import SwiftUI

struct CurrencyText: View {
    let amount: Decimal
    let currencySymbol: String
    let font: Font
    let color: Color
    
    init(
        amount: Decimal,
        currencySymbol: String = "₹",
        font: Font = Theme.monospacedFont(size: 18),
        color: Color = .primary
    ) {
        self.amount = amount
        self.currencySymbol = currencySymbol
        self.font = font
        self.color = color
    }
    
    private var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: amount as NSDecimalNumber) ?? "0.00"
    }
    
    var body: some View {
        Text("\(currencySymbol)\(formattedAmount)")
            .font(font)
            .foregroundColor(color)
    }
}

