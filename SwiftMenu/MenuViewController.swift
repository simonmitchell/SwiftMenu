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
        
        if let _menuItems = menuItems {

            for menuItem in _menuItems {
                containerStackView.insertArrangedSubview(MenuItemView(item: menuItem), atIndex: 0)
            }
        }
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
        case .Ended:
            
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
            })
        case .Changed:
            
            let touchedViews = containerStackView.arrangedSubviews.filter({
                return sender.touchWithinView($0)
            })
            
            hoveringView = touchedViews.first
            
        default:
            ""
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

extension MenuViewController: UIGestureRecognizerDelegate {
    
    public func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
