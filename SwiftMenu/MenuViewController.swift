//
//  MenuViewController.swift
//  Concact
//
//  Created by Simon Mitchell on 21/04/2016.
//  Copyright © 2016 Yellow Brick Bear. All rights reserved.
//

import UIKit

typealias MenuItemHandler = (menuItem: MenuItem) -> (Void)

public struct MenuItem {
    
    var title: String?
    var handler: MenuItemHandler?
}

public class MenuViewController: UIViewController {
    
    public var menuItems: [MenuItem]?
    
    private weak var attachedView: UIView?
    
    private weak var attachedViewController: UIViewController?
    
    private var gestureRecognizer: UILongPressGestureRecognizer?
    
    public init(menuItems initMenuItems: [MenuItem]) {
        
        menuItems = initMenuItems
        super.init(nibName: "MenuViewController", bundle: NSBundle(forClass: MenuViewController.self))
    }
    
    public func attachToView(view: UIView, inViewController: UIViewController) {
        
        attachedView = view
        if let _attachedView = attachedView, _gestureRecognizer = gestureRecognizer {
            
            _attachedView.removeGestureRecognizer(_gestureRecognizer)
            gestureRecognizer = nil
        }
        
        attachedViewController = inViewController
        
        let newGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(MenuViewController.handleGesture(_:)))
        newGestureRecognizer.minimumPressDuration = 0.01
        newGestureRecognizer.cancelsTouchesInView = false
        newGestureRecognizer.delegate = self
        view.addGestureRecognizer(newGestureRecognizer)
        gestureRecognizer = newGestureRecognizer
    }
    
    func handleGesture(sender: UILongPressGestureRecognizer) {
        
        switch sender.state {
        case .Began:
            
            if let viewController = attachedViewController where sender == gestureRecognizer && self.presentingViewController == nil {
                
                if let _gestureRecognizer = gestureRecognizer {
                    
                    // Switch the gesture recognizer over to this view
                    view.addGestureRecognizer(_gestureRecognizer)
                }
                viewController.presentViewController(self, animated: true, completion: nil)
            }
        case .Ended:
            
            if presentingViewController != nil {
                
                if let _gestureRecognizer = gestureRecognizer {
                    
                    // Remove the gesture recognizer
                    view.removeGestureRecognizer(_gestureRecognizer)
                    
                    // And switch it back to the attached view!
                    if let _attachedView = attachedView {
                        _attachedView.addGestureRecognizer(_gestureRecognizer)
                    }
                }
                
                self.dismissViewControllerAnimated(true, completion: nil)
            }
        default:
            ""
        }
    }
    
    public override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        print("Touch Ended!")
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
