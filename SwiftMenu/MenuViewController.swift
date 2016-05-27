//
//  MenuViewController.swift
//  Concact
//
//  Created by Simon Mitchell on 21/04/2016.
//  Copyright © 2016 Yellow Brick Bear. All rights reserved.
//

import UIKit

public typealias MenuItemHandler = (menuItem: MenuItem) -> (Void)

public struct MenuItem {
    
    public var title: String?
    public var handler: MenuItemHandler?
    public var tag: Int = 0
    public var subMenuItems: [MenuItem]?
    
    public init(title: String?, handler: MenuItemHandler?) {
        
        self.title = title
        self.handler = handler
    }
    
    public func hasSubMenu() -> Bool {
        
        guard let subMenuItems = subMenuItems where subMenuItems.count > 0 else { return false }
        return true
    }
}

public extension UIGestureRecognizer {
    
    func touchWithinView(view: UIView) -> Bool {
        
        let location = self.locationOfTouch(0, inView: view)
        return CGRectContainsPoint(view.bounds, location)
    }
}

public class MenuViewController: UIViewController {
    
    public var menuItems: [MenuItem]?
    
    private var menuItemViews: [MenuItemView]?
    
    private weak var attachedView: UIView?
    
    private weak var attachedViewController: UIViewController?
    
    private var gestureRecognizer: UILongPressGestureRecognizer?
    
    private var originalPresentationMode: UIModalPresentationStyle = .FullScreen
    
    private var menuStack: [MenuItem]?
    
    private var hoveringView: UIView? {
        willSet {
            
            guard newValue != hoveringView else { return }
            
            for view in containerStackView.arrangedSubviews {
                
                if let menuView = view as? MenuItemView {
                    menuView.selected = false
                }
            }
            
            if let menuView = newValue as? MenuItemView {
                menuView.selected = true
            }
        }
    }
    
    @IBOutlet weak var containerStackView: UIStackView!
    
    @IBOutlet weak var containerViewController: UIView!
    
    @IBOutlet weak var scrollUpView: UIImageView!
    
    @IBOutlet weak var scrollDownView: UIImageView!
    
    public init(menuItems initMenuItems: [MenuItem]) {
        
        menuItems = initMenuItems
        super.init(nibName: "MenuViewController", bundle: NSBundle(forClass: MenuViewController.self))
        
        providesPresentationContextTransitionStyle = true
        definesPresentationContext = true
        modalPresentationStyle = .OverCurrentContext
    }
    
    public func attachToView(view: UIView, inViewController: UIViewController) {
        
        if let _attachedView = attachedView, _gestureRecognizer = gestureRecognizer {
            
            _attachedView.removeGestureRecognizer(_gestureRecognizer)
            gestureRecognizer = nil
        }
        
        attachedView = view
        attachedViewController = inViewController
        
        originalPresentationMode = inViewController.modalPresentationStyle
        inViewController.modalPresentationStyle = .CurrentContext
        
        let newGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(MenuViewController.handleGesture(_:)))
        newGestureRecognizer.minimumPressDuration = 0.01
        newGestureRecognizer.cancelsTouchesInView = false
        newGestureRecognizer.delegate = self
        view.addGestureRecognizer(newGestureRecognizer)
        gestureRecognizer = newGestureRecognizer
    }
    
    public override func viewDidLoad() {
        
        super.viewDidLoad()
        modalTransitionStyle = .CrossDissolve
    }
    
    public override func viewWillAppear(animated: Bool) {
        
        super.viewWillAppear(animated)
        layoutMenuItemViews()
    }
    
    public override func viewWillDisappear(animated: Bool) {
        
        menuStack = []
    }
    
    private func layoutMenuItemViews() {
        
        // Clear up all old menu item views
        for subview in containerStackView.arrangedSubviews {
            if let menuItemView = subview as? MenuItemView {
                containerStackView.removeArrangedSubview(menuItemView)
            }
        }
        
        // Re-set the array
        menuItemViews = []
        
        var _menuItemViews: [MenuItemView] = []
        
        if let pushedMenuItem = menuStack?.last {
            
            if let subMenuItems = pushedMenuItem.subMenuItems {
                _menuItemViews = subMenuItems.map({ MenuItemView(item: $0) })
            }
            
        } else if let menuItems = menuItems {
            _menuItemViews = menuItems.map({ MenuItemView(item: $0) })
        }
        
        // Minus 1 because cancel button is also 62 points high
        let allowedItems = Int((UIScreen.mainScreen().bounds.size.height - (96)) / (62)) - 1
        
        var index = 0
        while index < allowedItems && index < _menuItemViews.count {
            containerStackView.addArrangedSubview(_menuItemViews[index])
            index += 1
        }
        
        if allowedItems < _menuItemViews.count {
            
            scrollUpView.alpha = 0.0
            scrollDownView.alpha = 1.0
        } else {
            
            scrollDownView.alpha = 0.0
            scrollUpView.alpha = 0.0
        }
        
        menuItemViews = _menuItemViews
    }
    
    private func pushMenuItem(menuItem: MenuItem) {
        
        var stack: [MenuItem] = []
        if let menuStack = menuStack {
            stack = menuStack
        }
        
        stack.append(menuItem)
        
        menuStack = stack
        layoutMenuItemViews()
    }
    
    func handleMaintainTouchGesture(sender: NSTimer) {
        
        // If our touch is in the scoll down or scroll up view
        
        print("Hovered over view \(hoveringView)")
        
        if hoveringView == scrollDownView && scrollDownView.alpha != 0 {
            scrollDown()
        } else if hoveringView == scrollUpView && scrollUpView.alpha != 0 {
            scrollUp()
        } else if let menuItemView = hoveringView as? MenuItemView where menuItemView.menuItem.hasSubMenu() {
            pushMenuItem(menuItemView.menuItem)
        }
    }
    
    private var hoveringTimer: NSTimer?
    
    func handleGesture(sender: UILongPressGestureRecognizer) {
        
        switch sender.state {
        case .Began:
            
            if let viewController = attachedViewController where sender == gestureRecognizer && self.presentingViewController == nil {
                
                viewController.presentViewController(self, animated: true, completion: {
                    
                    if let _gestureRecognizer = self.gestureRecognizer {
                        
                        // Switch the gesture recognizer over to this view
                        self.view.addGestureRecognizer(_gestureRecognizer)
                    }
                })
            }
            
        case .Ended/*, .Cancelled*/:
            
            if sender != gestureRecognizer { return }
            
            if let _gestureRecognizer = gestureRecognizer {
                
                // Remove the gesture recognizer
                view.removeGestureRecognizer(_gestureRecognizer)
                
                // And switch it back to the attached view!
                if let _attachedView = attachedView {
                    _attachedView.addGestureRecognizer(_gestureRecognizer)
                }
            }
            
            dismissViewControllerAnimated(true, completion: {
                self.attachedViewController?.modalPresentationStyle = self.originalPresentationMode
                
                if let selectedMenuView = self.hoveringView as? MenuItemView {
                    selectedMenuView.menuItem.handler?(menuItem: selectedMenuView.menuItem)
                }
                
                self.hoveringView = nil
            })
            
        case .Changed:
            
            var touchableViews = containerStackView.arrangedSubviews
            touchableViews.appendContentsOf([scrollDownView, scrollUpView])
            
            let touchedViews = touchableViews.filter({
                return sender.touchWithinView($0)
            })
            
            if let newHoveringView = touchedViews.first where newHoveringView != hoveringView {
                
                hoveringTimer?.invalidate()
                hoveringTimer = nil
                hoveringView = touchedViews.first
                hoveringTimer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: #selector(MenuViewController.handleMaintainTouchGesture(_:)), userInfo: nil, repeats: false)
                print("changed to hovering over view \(hoveringView)")
                
            } else if touchedViews.first == nil {
                
                hoveringTimer?.invalidate()
                hoveringTimer = nil
                hoveringView = nil
                print("not hovering over view")
            } else {
                
                print("still hovering over same view!")
            }
            
        default:
            ""
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func scrollUp() {
        scroll(true)
    }
    
    func scrollDown() {
        scroll(false)
    }
    
    func scroll(up: Bool) {
        
        print("scrolling up \(up)")
        
        guard let _menuItemViews = menuItemViews else { return }
        guard let firstArrangedView = containerStackView.arrangedSubviews.first as? MenuItemView, lastArrangedView = containerStackView.arrangedSubviews.last as? MenuItemView else { return }
        
        guard let currentTopIndex = _menuItemViews.indexOf(firstArrangedView),currentBottomIndex = _menuItemViews.indexOf(lastArrangedView) else { return }
        
        if up {
            
            if (currentTopIndex > 0) {
                
                // Remove the bottom view from the stack view
                containerStackView.removeArrangedSubview(lastArrangedView)
                // Insert the view from _menuItemViews for the index before the top most one
                containerStackView.insertArrangedSubview(_menuItemViews[currentTopIndex - 1], atIndex: 0)
                hoveringTimer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: #selector(MenuViewController.handleMaintainTouchGesture(_:)), userInfo: nil, repeats: false)
            }
            
        } else {
            
            if (currentBottomIndex < _menuItemViews.count - 1) {
                
                print("scrolling down!")
                
                // Remove the top view from the stack
                containerStackView.removeArrangedSubview(firstArrangedView)
                // Insert the view from _menuItemViews for the index after the bottom most one
                containerStackView.insertArrangedSubview(_menuItemViews[currentBottomIndex + 1], atIndex: containerStackView.arrangedSubviews.count)
                hoveringTimer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: #selector(MenuViewController.handleMaintainTouchGesture(_:)), userInfo: nil, repeats: false)
            }
        }

        
        UIView.animateWithDuration(0.3, delay: 0.0, options: [.AllowAnimatedContent], animations: {
            
            // If we're scrolling up, and the first arranged view isn't the first view from our menu item views, then we can scroll up
            
            self.scrollUpView.alpha = self.containerStackView.arrangedSubviews.first == _menuItemViews.first ? 0.0 : 1.0
            self.scrollDownView.alpha = self.containerStackView.arrangedSubviews.last == _menuItemViews.last ? 0.0 : 1.0
            
            }) { (complete) in
                
        }
        

    }
}

extension MenuViewController: UIGestureRecognizerDelegate {
    
    public func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
