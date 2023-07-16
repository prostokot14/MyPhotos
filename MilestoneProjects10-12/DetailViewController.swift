//
//  DetailViewController.swift
//  MilestoneProjects10-12
//
//  Created by Антон Кашников on 15.07.2023.
//

import UIKit

final class DetailViewController: UIViewController {
    @IBOutlet var detailImageView: UIImageView!
    
    var imagePath: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let imagePath else {
            return
        }
        
        detailImageView.image = UIImage(contentsOfFile: imagePath)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.hidesBarsOnTap = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.hidesBarsOnTap = false
    }
}
