//
//  Data.swift
//  NSTableViewWrapper
//
//  Created by Andreas Linnert on 16.03.25.
//

import Foundation

struct ListItem: Identifiable, Equatable, Hashable {
    var id: UUID = UUID()
    var name: String
    var description: String { name }
}

let items = (1...100).map { ListItem(name: "Item \($0)") }
