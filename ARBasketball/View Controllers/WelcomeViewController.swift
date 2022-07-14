//
//  WelcomeViewController.swift
//  ARBasketball
//
//  Created by Андрей on 14.07.2022.
//

import UIKit

class WelcomeViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet var startButton: UIButton!
    
    // MARK: - Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        startButton.layer.borderWidth = 3
        startButton.layer.borderColor = UIColor.white.cgColor
        startButton.layer.cornerRadius = 7
    }
    
    // MARK: - Actions
    @IBAction func unwind(_ segue: UIStoryboardSegue) {
        print(#line, #function)
    }
    
}
