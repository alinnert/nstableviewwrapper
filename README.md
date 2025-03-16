# NSTableView for SwiftUI

I'm trying to build a SwiftUI wrapper for NSTableView, so you can add lists with selection support to your SwiftUI-App.

**Current status:** ⚠️ in active development, not usable yet!

## Usage

```swift
struct YourCustomView: View {
  @State private var selection: Set<ListItem> = Set()

  var body: some View {
    TableViewWrapper(items: items, rowHeight: 30, selectedItems: $selection) { item in
      Text(item.name)
    }
  }
}
```

## Known issues

### Type restriction

Items currently must be of this type:

```swift
struct ListItem: Identifiable, Equatable, Hashable {
    var id: UUID = UUID()
    var name: String
    var description: String { name }
}
```

I plan to make TableViewWrapper generic in the future.

### Display problems on first render

The currently biggest issue: On first render the first few items are displayed incorrectly. As soon as those items go out of the visible area and enter it again the issue is magically gone. I'm still trying to figure out what causes this.
