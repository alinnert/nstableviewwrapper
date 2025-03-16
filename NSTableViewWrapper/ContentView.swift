//
//  ContentView.swift
//  NSTableViewWrapper
//
//  Created by Andreas Linnert on 16.03.25.
//

import SwiftUI

struct ContentView: View {
    @State private var selection: Set<ListItem> = Set()

    var body: some View {
        TableViewWrapper(items: items, rowHeight: 30, selectedItems: $selection) { item in
            Text(item.name)
        }
    }
}

#Preview {
    ContentView()
}
