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
    
    var title: String?
    var handler: MenuItemHandler?
    var tag: Int?
    
    public init(title: String?, handler: MenuItemHandler?) {
        
        self.title = title
        self.handler = handler
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
    }
    
    public override func viewWillAppear(animated: Bool) {
        
        super.viewWillAppear(animated)
        
        for subview in containerStackView.arrangedSubviews {
            if let menuItemView = subview as? MenuItemView {
                containerStackView.removeArrangedSubview(menuItemView)
            }
        }
        menuItemViews = []
        
        var _menuItemViews: [MenuItemView] = []
        
        if let _menuItems = menuItems {
            _menuItemViews = _menuItems.map({ MenuItemView(item: $0) })
        }
        
        // Minus 1 because cancel button is also 62 points high
        let allowedItems = Int((UIScreen.mainScreen().bounds.size.height - (96)) / (62)) - 1
        
        var index = 0
        while index < allowedItems {
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
            
            let touchedViews = containerStackView.arrangedSubviews.filter({
                return sender.touchWithinView($0)
            })
            
            hoveringView = touchedViews.first
            
            // If our touch is in the scoll down or scroll up view
            if sender.touchWithinView(scrollDownView) && scrollDownView.alpha != 0 {
                scroll(false)
            } else if sender.touchWithinView(scrollUpView) && scrollUpView.alpha != 0 {
                scroll(true)
            } else {
                scrollTimer?.invalidate()
                scrollTimer = nil
            }
            
        default:
            ""
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private var lockTime: NSTimeInterval = NSDate().timeIntervalSince1970
    
    /**
     Because the user has to actually move their finger for UIGestureRecognizer method to be called, we'll assume every 0.5 seconds they're on the button to scroll again
     */
    private var scrollTimer: NSTimer?
    
    func scrollUp() {
        scroll(true)
    }
    
    func scrollDown() {
        scroll(false)
    }
    
    func scroll(up: Bool) {
        
        if NSDate().timeIntervalSince1970 - lockTime < 0.5 {
            return
        }
        
        scrollTimer?.invalidate()
        scrollTimer = nil
        
        guard let _menuItemViews = menuItemViews else { return }
        guard let firstArrangedView = containerStackView.arrangedSubviews.first as? MenuItemView, lastArrangedView = containerStackView.arrangedSubviews.last as? MenuItemView else { return }
        
        guard let currentTopIndex = _menuItemViews.indexOf(firstArrangedView),currentBottomIndex = _menuItemViews.indexOf(lastArrangedView) else { return }
        
        // If we're scrolling up, and the first arranged view isn't the first view from our menu item views, then we can scroll up
        if up {
            
            if (currentTopIndex > 0) {
                
                lockTime = NSDate().timeIntervalSince1970
                // Remove the bottom view from the stack view
                containerStackView.removeArrangedSubview(lastArrangedView)
                // Insert the view from _menuItemViews for the index before the top most one
                containerStackView.insertArrangedSubview(_menuItemViews[currentTopIndex - 1], atIndex: 0)
                
                scrollTimer = NSTimer.scheduledTimerWithTimeInterval(0.51, target: self, selector:  #selector(MenuViewController.scrollUp), userInfo: nil, repeats: true)
            }
            
        } else {
            
            if (currentBottomIndex < _menuItemViews.count - 1) {
                
                lockTime = NSDate().timeIntervalSince1970
                // Remove the top view from the stack
                containerStackView.removeArrangedSubview(firstArrangedView)
                // Insert the view from _menuItemViews for the index after the bottom most one
                containerStackView.insertArrangedSubview(_menuItemViews[currentBottomIndex + 1], atIndex: containerStackView.arrangedSubviews.count)
                
                scrollTimer = NSTimer.scheduledTimerWithTimeInterval(0.51, target: self, selector:  #selector(MenuViewController.scrollDown), userInfo: nil, repeats: true)
            }
        }
        
        print("current top index \(currentTopIndex)")
        print("current bottom index \(currentBottomIndex)")
        print("item views: \(_menuItemViews.count)")
        
        scrollUpView.alpha = containerStackView.arrangedSubviews.first == _menuItemViews.first ? 0.0 : 1.0
        scrollDownView.alpha = containerStackView.arrangedSubviews.last == _menuItemViews.last ? 0.0 : 1.0
    }
}

extension MenuViewController: UIGestureRecognizerDelegate {
    
    public func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
