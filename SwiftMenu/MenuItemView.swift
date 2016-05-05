//
//  MenuItemView.swift
//  SwiftMenu
//
//  Created by Simon Mitchell on 21/04/2016.
//  Copyright © 2016 yellowbrickbear. All rights reserved.
//

import UIKit

internal class MenuItemView: UIView {
    
    internal let menuItem: MenuItem
    
    private let titleLabel: UILabel
    
    private let singlePixelLine: UIView = UIView()
    
    internal var selected: Bool = false {
        didSet {
            titleLabel.textColor = selected ? UIColor.whiteColor() : UIColor.blackColor()
            backgroundColor = selected ? UIColor(red:0.180,  green:0.286,  blue:0.404, alpha:1) : UIColor.whiteColor()
        }
    }

    internal init(item: MenuItem) {
        
        menuItem = item
        titleLabel = UILabel()
        super.init(frame: CGRectZero)
        
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        
        menuItem = MenuItem(title: "", handler: nil)
        titleLabel = UILabel()
        super.init(coder: aDecoder)
        
        setupViews()
    }
    
    private func setupViews() {
        
        addSubview(titleLabel)
        titleLabel.text = menuItem.title
        titleLabel.font = UIFont.systemFontOfSize(18)
        titleLabel.textAlignment = .Center
        titleLabel.numberOfLines = 0
        titleLabel.adjustsFontSizeToFitWidth = true
        
        singlePixelLine.backgroundColor = UIColor.blackColor()
        addSubview(singlePixelLine)
    }
    
    override func layoutSubviews() {
        
        super.layoutSubviews()
        
        let constrainedSize = titleLabel.sizeThatFits(CGSizeMake(CGFloat(MAXFLOAT), CGFloat(MAXFLOAT)))
        titleLabel.frame = CGRectMake(0, 0, frame.width - 18, constrainedSize.height)
        titleLabel.center = CGPointMake(bounds.width/2, bounds.height/2)
        
        let pixelSize = 1 / UIScreen.mainScreen().scale
        singlePixelLine.frame = CGRectMake(0, bounds.size.height - pixelSize, bounds.size.width, pixelSize)
    }
    
    override func intrinsicContentSize() -> CGSize {
        
        var superSize = super.intrinsicContentSize()
        superSize.height = 62
        return superSize
    }
}
