//
//  PersonCell.swift
//  People
//
//  Created by Huy Bui on 2022-07-15.
//

import UIKit

class PersonUICollectionViewCell: UICollectionViewCell {
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var label: UILabel!
    
    override var isHighlighted: Bool {
        didSet {
            toggleIsHighlighted()
//            isHighlighted ? print("Cell highlighed") : print("Cell unhighlighed")
        }
    }

    func toggleIsHighlighted() {
        UIView.animate(withDuration: 0.1, delay: 0, options: [.curveEaseOut], animations: {
            self.alpha = self.isHighlighted ? 0.9 : 1.0
            self.transform = self.isHighlighted ?
                CGAffineTransform.identity.scaledBy(x: 0.97, y: 0.97) :
                CGAffineTransform.identity
        })
    }
    
}
