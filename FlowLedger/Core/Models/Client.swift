//
//  Client.swift
//  FlowLedger
//
//  Created by Pankaj Gaikar on 02/11/25.
//

import Foundation
import SwiftData

@Model
final class Client {
    var id: UUID
    var name: String
    var email: String?
    var phone: String?
    var address: String?
    var createdAt: Date
    var invoices: [Invoice]?
    
    init(name: String, email: String? = nil, phone: String? = nil, address: String? = nil) {
        self.id = UUID()
        self.name = name
        self.email = email
        self.phone = phone
        self.address = address
        self.createdAt = Date()
    }
}

