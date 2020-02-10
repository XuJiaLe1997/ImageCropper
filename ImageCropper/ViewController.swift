//
//  ViewController.swift
//  ImageCropper
//
//  Created by Xujiale on 2020/2/10.
//  Copyright © 2020 xujiale. All rights reserved.
//

import Foundation
import UIKit

class MainViewController: UITableViewController, DRImageCropperDelegate {
    
    @IBOutlet weak var imgView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = DRImageCropperViewController()
        vc.delegate = self
        present(vc, animated: false, completion: nil)
    }
    
    func imageCropper(_ cropperViewController: DRImageCropperViewController, editImg: UIImage) {
        print("裁剪完成")
        imgView.image = editImg
    }
    
    func imageCropperDidCancel(_ cropperViewController: DRImageCropperViewController) {
        print("取消裁剪")
    }
}
