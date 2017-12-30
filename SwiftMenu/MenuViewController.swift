//
//  MenuViewController.swift
//  Concact
//
//  Created by Simon Mitchell on 21/04/2016.
//  Copyright © 2016 Yellow Brick Bear. All rights reserved.
//

import UIKit

public typealias MenuItemHandler = (_ menuItem: MenuItem) -> (Void)

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
        
        guard let subMenuItems = subMenuItems, subMenuItems.count > 0 else { return false }
        return true
    }
}

public extension UIGestureRecognizer {
    
    func isTouchWithinView(_ view: UIView) -> Bool {
        
        let touchLocation = location(ofTouch: 0, in: view)
        return view.bounds.contains(touchLocation)
    }
}

public class MenuViewController: UIViewController {
    
    public var menuItems: [MenuItem]?
    
    private var menuItemViews: [MenuItemView]?
    
    private weak var attachedView: UIView?
    
    private weak var attachedViewController: UIViewController?
    
    private var gestureRecognizer: UILongPressGestureRecognizer?
    
    private var tapGestureRecognizer: UITapGestureRecognizer?
    
    private var originalPresentationMode: UIModalPresentationStyle = .fullScreen
    
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
        let bundle = Bundle(for: MenuViewController.self)
        super.init(nibName: "MenuViewController", bundle: bundle)
        
        providesPresentationContextTransitionStyle = true
        definesPresentationContext = true
        modalPresentationStyle = .overCurrentContext
        modalTransitionStyle = .crossDissolve
    }
    
    public func attachToView(_ view: UIView, in viewController: UIViewController) {
        
        if let attachedView = attachedView, let gestureRecognizer = gestureRecognizer {
            
            attachedView.removeGestureRecognizer(gestureRecognizer)
            self.gestureRecognizer = nil
        }
        
        attachedView = view
        attachedViewController = viewController
        
        originalPresentationMode = viewController.modalPresentationStyle
        viewController.modalPresentationStyle = .currentContext
        
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
    
    public override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        layoutMenuItemViews()
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        
        super.viewWillDisappear(animated)
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
        let allowedItems = Int((UIScreen.main.bounds.size.height - (96)) / (62)) - 1
        
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
    
    private func push(menuItem: MenuItem) {
        
        var stack: [MenuItem] = []
        if let menuStack = menuStack {
            stack = menuStack
        }
        
        stack.append(menuItem)
        
        menuStack = stack
        layoutMenuItemViews()
    }
    
    @objc func handleMaintainTouchGesture(sender: Timer) {
        
        // If our touch is in the scoll down or scroll up view
        
        if hoveringView == scrollDownView && scrollDownView.alpha != 0 {
            scrollDown()
        } else if hoveringView == scrollUpView && scrollUpView.alpha != 0 {
            scrollUp()
        } else if let menuItemView = hoveringView as? MenuItemView, menuItemView.menuItem.hasSubMenu() {
            push(menuItem: menuItemView.menuItem)
        } else if tapGestureRecognizer != nil {
            dismiss()
        }
    }
    
    private var hoveringTimer: Timer?
    
    @objc func handleTapGesture(_ sender: UITapGestureRecognizer) {
        handleTap(sender, timer: false)
    }
    
    @objc func handleGesture(_ sender: UILongPressGestureRecognizer) {
        
        switch sender.state {
        case .began:
            
            if var viewController = attachedViewController, sender == gestureRecognizer && self.presentingViewController == nil {
                
                if let tabBarController = viewController.tabBarController  {
                    viewController = tabBarController
                }
                
                viewController.present(self, animated: true, completion: {
                    
                    if let gestureRecognizer = self.gestureRecognizer {
                        
                        // Switch the gesture recognizer over to this view
                        self.view.addGestureRecognizer(gestureRecognizer)
                    }
                })
            }
            
            break
            
        case .ended, .cancelled:
            
            if sender != gestureRecognizer { return }
            
            if let _gestureRecognizer = gestureRecognizer {
                
                // Remove the gesture recognizer
                view.removeGestureRecognizer(_gestureRecognizer)
                
                // And switch it back to the attached view!
                
                if sender.state == .cancelled {
                    
                    let newGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(MenuViewController.handleTapGesture(_:)))
                    newGestureRecognizer.cancelsTouchesInView = false
                    tapGestureRecognizer = newGestureRecognizer
                    self.view.addGestureRecognizer(tapGestureRecognizer!)
                    
                } else {
                    
                    if let _attachedView = attachedView {
                        _attachedView.addGestureRecognizer(_gestureRecognizer)
                    }
                }
            }
            
            // We don't want to dismiss if the user has tapped into the menu
            if sender.state == .ended && sender == gestureRecognizer && tapGestureRecognizer == nil {
                dismiss()
            }
            
            break
            
        case .changed:
            
            handleTap(sender, timer: true)
            
            break
            
        default:
            break
        }
    }
    
    func dismiss() {
        
        dismiss(animated: true) {
            
            self.attachedViewController?.modalPresentationStyle = self.originalPresentationMode
            
            if let selectedMenuView = self.hoveringView as? MenuItemView {
                selectedMenuView.menuItem.handler?(selectedMenuView.menuItem)
            }
            
            self.hoveringView = nil
            
            if let tapGestureRecognizer = self.tapGestureRecognizer {
                self.view.removeGestureRecognizer(tapGestureRecognizer)
                self.tapGestureRecognizer = nil
            }
        }
    }
    
    func handleTap(_ sender: UIGestureRecognizer, timer: Bool) {
    
        var touchableViews = containerStackView.arrangedSubviews
        touchableViews.append(contentsOf: [scrollDownView, scrollUpView])
        
        let touchedViews = touchableViews.filter({
            return sender.isTouchWithinView($0)
        })
        
        if !timer {
            
            hoveringView = touchedViews.first
            handleMaintainTouchGesture(sender: Timer())
            
        } else if let newHoveringView = touchedViews.first, newHoveringView != hoveringView {
            
            hoveringTimer?.invalidate()
            hoveringTimer = nil
            hoveringView = touchedViews.first
            hoveringTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(handleMaintainTouchGesture(sender:)), userInfo: nil, repeats: false)
            
        } else if touchedViews.first == nil {
            
            hoveringTimer?.invalidate()
            hoveringTimer = nil
            hoveringView = nil
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func scrollUp() {
        scroll(up: true)
    }
    
    func scrollDown() {
        scroll(up: false)
    }
    
    func scroll(up: Bool) {
        
        print("scrolling up \(up)")
        
        guard let menuItemViews = menuItemViews else { return }
        guard let firstArrangedView = containerStackView.arrangedSubviews.first as? MenuItemView, let lastArrangedView = containerStackView.arrangedSubviews.last as? MenuItemView else { return }
        
        guard let currentTopIndex = menuItemViews.index(of: firstArrangedView), let currentBottomIndex = menuItemViews.index(of: lastArrangedView) else { return }
        
        if up {
            
            if (currentTopIndex > 0) {
                
                // Remove the bottom view from the stack view
                containerStackView.removeArrangedSubview(lastArrangedView)
                // Insert the view from _menuItemViews for the index before the top most one
                containerStackView.insertArrangedSubview(menuItemViews[currentTopIndex - 1], at: 0)
                
                if tapGestureRecognizer == nil {
                    hoveringTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(handleMaintainTouchGesture(sender:)), userInfo: nil, repeats: false)
                }
            }
            
        } else {
            
            if (currentBottomIndex < menuItemViews.count - 1) {
                
                print("scrolling down!")
                
                // Remove the top view from the stack
                containerStackView.removeArrangedSubview(firstArrangedView)
                // Insert the view from _menuItemViews for the index after the bottom most one
                containerStackView.insertArrangedSubview(menuItemViews[currentBottomIndex + 1], at: containerStackView.arrangedSubviews.count)
                
                if tapGestureRecognizer == nil {
                    hoveringTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(handleMaintainTouchGesture(sender:)), userInfo: nil, repeats: false)
                }
            }
        }

        
        UIView.animate(withDuration: 0.3, delay: 0.0, options: [.allowAnimatedContent], animations: {
            
            // If we're scrolling up, and the first arranged view isn't the first view from our menu item views, then we can scroll up
            
            self.scrollUpView.alpha = self.containerStackView.arrangedSubviews.first == menuItemViews.first ? 0.0 : 1.0
            self.scrollDownView.alpha = self.containerStackView.arrangedSubviews.last == menuItemViews.last ? 0.0 : 1.0
            
        }, completion: nil)
    }
}

extension MenuViewController: UIGestureRecognizerDelegate {
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
