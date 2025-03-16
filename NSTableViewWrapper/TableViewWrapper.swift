//
//  TableViewWrapper.swift
//  NSTableViewWrapper
//
//  Created by Andreas Linnert on 16.03.25.
//

import SwiftUI

struct TableViewWrapper<RowContent: View>: NSViewControllerRepresentable {
    let items: [ListItem]
    let rowHeight: CGFloat
    @Binding var selectedItems: Set<ListItem>
    var rowContent: (ListItem) -> RowContent

    func makeNSViewController(context: Context) -> NSTableViewController<
        RowContent
    > {
        return NSTableViewController(
            items: items,
            rowHeight: rowHeight,
            selectedItems: $selectedItems,
            rowContent: rowContent
        )
    }

    func updateNSViewController(
        _ nsViewController: NSTableViewController<RowContent>, context: Context
    ) {
        nsViewController.rowContent = rowContent
        nsViewController.update(with: items, selectedItems: selectedItems)
    }
}

class NSTableViewController<RowContent: View>: NSViewController,
                                               NSTableViewDelegate
{
    let tableView = NSTableView()
    let scrollView = NSScrollView()
    private var dataSource: NSTableViewDiffableDataSource<Int, ListItem>!
    @Binding var selectedItems: Set<ListItem>
    var rowContent: (ListItem) -> RowContent

    init(
        items: [ListItem],
        rowHeight: CGFloat,
        selectedItems: Binding<Set<ListItem>>,
        rowContent: @escaping (ListItem) -> RowContent
    ) {
        self._selectedItems = selectedItems
        self.rowContent = rowContent
        super.init(nibName: nil, bundle: nil)
        setupTableView(items: items, rowHeight: rowHeight)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupTableView(items: [ListItem], rowHeight: CGFloat) {
        let column = NSTableColumn(
            identifier: NSUserInterfaceItemIdentifier("Column")
        )
        column.title = "Name"

        tableView.addTableColumn(column)
        tableView.delegate = self

        tableView.allowsMultipleSelection = true
        tableView.headerView = nil
        tableView.rowHeight = max(rowHeight, 16)

        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.frame = view.bounds
        scrollView.autoresizingMask = [.width, .height]

        view.addSubview(scrollView)

        dataSource = NSTableViewDiffableDataSource(tableView: tableView) {
            tableView, tableColumn, row, item in

            let hostingView = CustomHostingView(rootView: self.rowContent(item))
            hostingView.tableView = tableView
            hostingView.row = row
            hostingView.autoresizingMask = [.width, .height]
            hostingView.translatesAutoresizingMaskIntoConstraints = false

            return hostingView
        }

        update(with: items, selectedItems: $selectedItems.wrappedValue)
    }

    func update(with items: [ListItem], selectedItems: Set<ListItem>) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, ListItem>()
        snapshot.appendSections([0])
        snapshot.appendItems(items)
        dataSource.apply(snapshot, animatingDifferences: true)

        for row in 0..<tableView.numberOfRows {
            guard let item = dataSource.itemIdentifier(forRow: row),
                  let hostingView = tableView.view(
                    atColumn: 0, row: row, makeIfNecessary: false
                  ) as? NSHostingView<RowContent>
            else { continue }

            if let tableCellView = hostingView.superview as? NSTableCellView {
                print(
                    "↕ row \(row) tableCellView constraints:",
                    tableCellView.constraints
                )
            } else {
                print(
                    "no table cell view in row \(row), instead:",
                    hostingView.superview
                )
            }

            print(
                "↕ row \(row) intrinsic height:",
                hostingView.intrinsicContentSize.height
            )
            print("↕ row \(row) bounds height:", hostingView.bounds.height)
            print("↕ row \(row) constraints:", hostingView.constraints)

            hostingView.rootView = self.rowContent(item)

            //            print("↕ row \(row) intrinsic height:", cell.intrinsicContentSize.height)
            //            print("↕ row \(row) bounds height:", cell.bounds.height)
            //            print("↕ row \(row) constraints:", cell.constraints)
        }

        let selectedIndexes = IndexSet(
            items.enumerated().compactMap { index, item in
                selectedItems.contains(item) ? index : nil
            })

        if tableView.selectedRowIndexes != selectedIndexes {
            tableView.selectRowIndexes(selectedIndexes, byExtendingSelection: false)
        }
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        guard let item = dataSource.itemIdentifier(forRow: row) else {
            return tableView.rowHeight
        }

        let hostingView = NSHostingView(rootView: self.rowContent(item))
        let size = hostingView.fittingSize

        //        print("↕ row \(row) intrinsic height: \(hostingView.intrinsicContentSize.height)")
        //        print("↕ row \(row) bounds height: \(hostingView.bounds.height)")
        //        print("↕ row \(row) fitting size: \(size)")

        return tableView.rowHeight
        //        return max(size.height, tableView.rowHeight)
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        let newSelection = Set(
            tableView.selectedRowIndexes.compactMap { index in
                dataSource.itemIdentifier(forRow: index)
            })

        if newSelection != selectedItems {
            DispatchQueue.main.async {
                self.selectedItems = newSelection
            }
        }
    }

    class CustomHostingView<Content: View>: NSHostingView<Content> {
        weak var tableView: NSTableView?
        var row: Int?
        var constraintsAdded = false // Flag, um sicherzustellen, dass Constraints nur einmal hinzugefügt werden

        override func viewWillDraw() {
            super.viewWillDraw()

            if let tableView, let row {
                tableView.noteHeightOfRows(withIndexesChanged: IndexSet([row]))
            }
        }

        override func viewDidChangeEffectiveAppearance() {
            super.viewDidChangeEffectiveAppearance()

            if let tableView, let row {
                let index = IndexSet([row])
                tableView.noteHeightOfRows(withIndexesChanged: index)
            }
        }
    }
}
