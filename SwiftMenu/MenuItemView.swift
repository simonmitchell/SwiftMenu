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
    
    private let titleLabel: UILabel = UILabel()
    
    private let singlePixelLine: UIView = UIView()
    
    private let chevronImageView = UIImageView()
    
    internal var selected: Bool = false {
        didSet {
            titleLabel.textColor = selected ? .white : .black
            backgroundColor = selected ? UIColor(red:0.180,  green:0.286,  blue:0.404, alpha:1) : .white
        }
    }

    internal init(item: MenuItem) {
        
        menuItem = item
        super.init(frame: .zero)
        
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        
        menuItem = MenuItem(title: "", handler: nil)
        super.init(coder: aDecoder)
        setupViews()
    }
    
    private func setupViews() {
        
        addSubview(titleLabel)
        titleLabel.text = menuItem.title
        titleLabel.font = UIFont.systemFont(ofSize: 18)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.adjustsFontSizeToFitWidth = true
        
        singlePixelLine.backgroundColor = .black
        addSubview(singlePixelLine)
        
        if let _ = menuItem.subMenuItems {
            addSubview(chevronImageView)
            
            let bundle = Bundle(for: MenuItemView.self)
            chevronImageView.image = UIImage(named: "Chevron", in: bundle, compatibleWith: nil)
        }
    }
    
    override func layoutSubviews() {
        
        super.layoutSubviews()
        
        chevronImageView.sizeToFit()
        
        if let _ = menuItem.subMenuItems {
            
            let constrainedSize = titleLabel.sizeThatFits(CGSize(width: frame.width - 18 - chevronImageView.bounds.width - 16, height: .greatestFiniteMagnitude))
            chevronImageView.frame = CGRect(x: frame.maxX - chevronImageView.bounds.width - 16, y: bounds.midY - chevronImageView.bounds.height/2, width: chevronImageView.bounds.width, height: chevronImageView.bounds.height)
            titleLabel.frame = CGRect(x: 0, y: 0, width: frame.width - 18 - chevronImageView.bounds.width - 16, height: constrainedSize.height)
            
        } else {
            
            let constrainedSize = titleLabel.sizeThatFits(CGSize(width: frame.width - 18, height: .greatestFiniteMagnitude))
            titleLabel.frame = CGRect(x: 0, y: 0, width: frame.width - 18, height: constrainedSize.height)
        }
        
        titleLabel.center = CGPoint(x: bounds.width/2, y: bounds.height/2)
        
        let pixelSize = 1 / UIScreen.main.scale
        singlePixelLine.frame = CGRect(x: 0, y: bounds.size.height - pixelSize, width: bounds.size.width, height: pixelSize)
    }
    
    override var intrinsicContentSize: CGSize {
        var superSize = super.intrinsicContentSize
        superSize.height = 62
        return superSize
    }
}
