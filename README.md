# SwiftMenu

A nice dropdown style menu for iOS

SwiftMenu functions as a dropdown menu which expands when the user hits a certain UI element, and dismisses when they take their finger off the screen (Either with a menu item selected, or not)

# Installation

## Carthage

## Manual
Setting up your app to use SwiftMenu is a simple and quick process. For now SwiftMenu is built as a static framework, meaning you will need to include the whole Xcode project in your workspace.

+ Drag all included files and folders to a location within your existing project.
+ Add SwiftMenu.framework to your Embedded Binaries.
+ Wherever you want to use SwiftMenu use `import SwiftMenu`.

# Usage

SwiftMenu is similar in API usage to `UIAlertViewController`. The class `MenuViewController` acts as the `UIAlertViewController` and `MenuItem` acts as a `UIAlertAction`. The `MenuViewController` is then 'attached' to a UIView which the user wants to display it on press.

To set up a simple menu you would do the following:
```swift
let firstMenuItem = MenuItem(title: "A Menu Item", handler: { menuItem in
  // Do some action
})
let secondMenuItem = MenuItem(title: "Another Menu Item", handler: nil)

let menuViewController = MenuViewController(menuItems: [firstMenuItem, secondMenuItem])
menuViewController.attachToView(someView, inViewController: self)
```

`MenuViewController` will then be responsible for managing when the menu should be shown and hidden.

# Features

- Unlimited menu items, with a hold to scroll mechanism (Subject to change)
- Automatic display and dismissal of the menu

# Coming Soon

- Support for nested menus
- Selection state of MenuItems
- Images on Menu Items

#License
See [LICENSE](LICENSE)
