//
//  PrimaryButton.swift
//  FlowLedger
//
//  Created by Pankaj Gaikar on 02/11/25.
//

import SwiftUI

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.bodyFont(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Theme.primary)
                .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

struct SecondaryButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.bodyFont(size: 16, weight: .medium))
                .foregroundColor(Theme.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Theme.primary.opacity(0.1))
                .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

