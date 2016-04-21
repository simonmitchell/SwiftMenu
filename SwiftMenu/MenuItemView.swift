//
//  MenuItemView.swift
//  SwiftMenu
//
//  Created by Simon Mitchell on 21/04/2016.
//  Copyright © 2016 yellowbrickbear. All rights reserved.
//

import UIKit

internal class MenuItemView: UIView {
    
    private let menuItem: MenuItem
    
    private let titleLabel: UILabel
    
    private let singlePixelLine: UIView = UIView()

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
        
        let constrainedSize = CGSizeMake(frame.width - 18, frame.height - 50)
        titleLabel.frame = CGRectMake(0, 0, constrainedSize.width, constrainedSize.height)
        titleLabel.center = CGPointMake(bounds.width/2, bounds.height/2)
        
        singlePixelLine.frame = CGRectMake(0, bounds.size.height - 1, bounds.size.width, 1)
    }
    
    override func intrinsicContentSize() -> CGSize {
        
        var superSize = super.intrinsicContentSize()
        
        let constrainedSize = CGSizeMake(superSize.width - 18, CGFloat(MAXFLOAT))
        titleLabel.frame = CGRectMake(0, 0, constrainedSize.width, constrainedSize.height)
        titleLabel.center = CGPointMake(bounds.width/2, bounds.height/2)
        
        let labelSize = titleLabel.sizeThatFits(constrainedSize)
        
        superSize.height = labelSize.height + 50
        return superSize
    }
}
