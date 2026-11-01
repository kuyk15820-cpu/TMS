//
//  VMTabBarCtrl.swift
//  iMemScan
//
//  Created by yiming on 2021/7/11.
//

import UIKit

class VMTabBarCtrl: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        setupCtrls()
    }
    
    func setupCtrls() {

        // 隐藏黑线
        self.tabBar.clipsToBounds = true

        let titles = [
            NSLocalizedString("Scripts", comment: "Scripts")
        ]
        
        // ไอคอนประจำแท็บ
        let images = [
            "doc.plaintext"
        ]
        
        // เหลือแค่ CustomFeatureCtrl หน้าเดียว
        let ctrls = [
            CustomFeatureCtrl.self
        ]

        var array = [UINavigationController]()
        for i in 0..<titles.count {
            let ctrl = ctrls[i].init()
            ctrl.tabBarItem.image = UIImage(systemName: images[i])
            ctrl.tabBarItem.badgeColor = .black
            ctrl.title = titles[i]
            let nav = UINavigationController.init(rootViewController: ctrl)
            array.append(nav)
        }

        self.viewControllers = array
        
        // 🟢 ซ่อน Tab Bar ด้านล่างทิ้งไปเลย เนื่องจากมีหน้าจอเดียว
        self.tabBar.isHidden = true
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
