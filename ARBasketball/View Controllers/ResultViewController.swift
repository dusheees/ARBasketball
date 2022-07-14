//
//  ResultViewController.swift
//  ARBasketball
//
//  Created by Андрей on 14.07.2022.
//

import UIKit

class ResultViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet var scoreLabel: UILabel!
    
    // MARK: - Properties
    var textLabel: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        
        scoreLabel.layer.borderWidth = 3
        scoreLabel.layer.borderColor = UIColor.white.cgColor
        scoreLabel.layer.cornerRadius = 7
        scoreLabel.text = textLabel
    }
}

