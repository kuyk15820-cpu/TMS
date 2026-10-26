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
            NSLocalizedString("Processes", comment: "Process"),
            NSLocalizedString("Search", comment: "Search"),
            NSLocalizedString("Scripts", comment: "Scripts"), // 🟢 เพิ่มชื่อแท็บสำหรับหน้าใหม่
            NSLocalizedString("Record", comment: "Record"),
            NSLocalizedString("Memory", comment: "Memory"),
            NSLocalizedString("Settings", comment: "Settings")
        ]
        
        // ไอคอนประจำแต่ละแท็บ (เพิ่มไอคอนสำหรับหน้า Script ด้วย)
        let images = [
            "app.badge", 
            "magnifyingglass", 
            "doc.plaintext", // 🟢 ไอคอนสำหรับหน้า CustomFeatureCtrl
            "square.and.pencil", 
            "doc.text.magnifyingglass", 
            "gear"
        ]
        
        // คลาสของแต่ละหน้าจอ (แทรก CustomFeatureCtrl เข้าไปในลำดับที่ 3)
        let ctrls = [
            VMTargetCtrl.self, 
            VMSearchCtrl.self, 
            CustomFeatureCtrl.self, // 🟢 หน้าใหม่ที่เราเพิ่งสร้าง
            VMRecordCtrl.self, 
            VMMemCtrl.self, 
            VMSetCtrl.self
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
