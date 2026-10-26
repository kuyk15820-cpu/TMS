//
//  CustomFeatureCtrl.swift
//  iMemScan
//
//  Created by Custom on 2026.
//

import UIKit

class CustomFeatureCtrl: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var featureList: [[String: Any]] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "H5GG Style Scripts (I32)"
        view.backgroundColor = .systemBackground
        
        setupNavButtons()
        setupTableView()
        loadFeaturesFromJson()
    }
    
    func setupNavButtons() {
        // ปุ่ม + สำหรับเพิ่มฟีเจอร์ใหม่
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addNewFeatureAlert)
        )
    }
    
    lazy var tableView: UITableView = {
        let tv = UITableView(frame: view.bounds, style: .insetGrouped)
        tv.delegate = self
        tv.dataSource = self
        tv.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return tv
    }()
    
    func setupTableView() {
        view.addSubview(tableView)
    }
    
    // MARK: - จัดการ JSON ใน Application Support
    
    func getJSONFilePath() -> URL {
        let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let supportDir = paths[0]
        
        if !FileManager.default.fileExists(atPath: supportDir.path) {
            try? FileManager.default.createDirectory(at: supportDir, withIntermediateDirectories: true, attributes: nil)
        }
        
        return supportDir.appendingPathComponent("h5gg_features.json")
    }
    
    func saveFeaturesToJson() {
        let url = getJSONFilePath()
        do {
            let data = try JSONSerialization.data(withJSONObject: featureList, options: .prettyPrinted)
            try data.write(to: url)
            print("Successfully saved to Application Support: \(url.path)")
        } catch {
            print("Failed to save JSON: \(error.localizedDescription)")
        }
    }
    
    func loadFeaturesFromJson() {
        let url = getJSONFilePath()
        guard let data = try? Data(contentsOf: url),
              let jsonArray = try? JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] else {
            return
        }
        featureList = jsonArray
        tableView.reloadData()
    }
    
    // MARK: - เพิ่มฟีเจอร์ใหม่ (กรอกเฉพาะชื่อ, ค่าเดิม, ค่าใหม่)
    
    @objc func addNewFeatureAlert() {
        let alert = UIAlertController(title: "Add Script Feature", message: "Enter feature name, original value, and target value (I32 fixed)", preferredStyle: .alert)
        
        alert.addTextField { tf in
            tf.placeholder = "Feature Name (e.g. GodMode)"
        }
        alert.addTextField { tf in
            tf.placeholder = "Original Value (e.g. 909000004)"
            tf.keyboardType = .numberPad
        }
        alert.addTextField { tf in
            tf.placeholder = "Modified Value (e.g. 909040010)"
            tf.keyboardType = .numberPad
        }
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let self = self,
                  let name = alert.textFields?[0].text, !name.isEmpty,
                  let origVal = alert.textFields?[1].text, !origVal.isEmpty,
                  let modVal = alert.textFields?[2].text, !modVal.isEmpty else { return }
            
            let newDict: [String: Any] = [
                "name": name,
                "originalValue": origVal,
                "modifiedValue": modVal,
                "type": "I32",        // ล็อคประเภทเป็น I32 ตายตัว
                "isEnabled": false    // สถานะสวิตช์เริ่มต้นเป็นปิด
            ]
            
            self.featureList.append(newDict)
            self.saveFeaturesToJson()
            self.tableView.reloadData()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - ทำงานจริงผ่าน VMTool เมื่อกดเปิด/ปิดสวิตช์ (สไตล์ H5GG)
    
    @objc func switchChanged(_ sender: UISwitch) {
        let index = sender.tag
        var item = featureList[index]
        
        let isOn = sender.isOn
        item["isEnabled"] = isOn
        featureList[index] = item
        saveFeaturesToJson() // บันทึกสถานะล่าสุดลง JSON
        
        let name = item["name"] as? String ?? ""
        let origVal = item["originalValue"] as? String ?? ""
        let modVal = item["modifiedValue"] as? String ?? ""
        
        // กำหนดประเภทเป็น I32 และรูปแบบการเปรียบเทียบ
        let valueType = VMMemValueType.I32
        let comparison = VMMemComparisonEQ
        
        if isOn {
            print("[\(name)] OPEN: Search \(origVal) (I32) -> Edit to \(modVal) (I32) -> Clear")
            
            // 🟢 1. เปิดสวิตช์: ค้นหาค่าเดิม -> แก้ไขเป็นค่าใหม่ทั้งหมด -> รีเซ็ตเคลียร์ผลลัพธ์
            VMTool.share().searchValue(origVal, type: valueType, comparison: comparison) { count, array in
                if count > 0 {
                    for model in array {
                        if let memModel = model as? MemModel {
                            memModel.value = modVal
                            memModel.type = valueType
                            VMTool.share().modifyValue(modVal, address: memModel.address, type: valueType)
                        }
                    }
                    print("[\(name)] Successfully modified \(count) addresses to \(modVal)")
                } else {
                    print("[\(name)] Original value not found!")
                }
                VMTool.share().reset()
            }
            
        } else {
            print("[\(name)] CLOSE: Search \(modVal) (I32) -> Revert to \(origVal) (I32) -> Clear")
            
            // 🟢 2. ปิดสวิตช์: ค้นหาค่าใหม่ -> สลับกลับเป็นค่าเดิม -> รีเซ็ตเคลียร์ผลลัพธ์
            VMTool.share().searchValue(modVal, type: valueType, comparison: comparison) { count, array in
                if count > 0 {
                    for model in array {
                        if let memModel = model as? MemModel {
                            memModel.value = origVal
                            memModel.type = valueType
                            VMTool.share().modifyValue(origVal, address: memModel.address, type: valueType)
                        }
                    }
                    print("[\(name)] Successfully reverted \(count) addresses to \(origVal)")
                } else {
                    print("[\(name)] Modified value not found!")
                }
                VMTool.share().reset()
            }
        }
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return featureList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "H5GGCell")
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "H5GGCell")
        }
        
        let item = featureList[indexPath.row]
        let name = item["name"] as? String ?? ""
        let origVal = item["originalValue"] as? String ?? ""
        let modVal = item["modifiedValue"] as? String ?? ""
        let isEnabled = item["isEnabled"] as? Bool ?? false
        
        cell?.textLabel?.text = name
        cell?.detailTextLabel?.text = "Orig: \(origVal) ➔ New: \(modVal) (I32)"
        cell?.detailTextLabel?.textColor = .systemGray
        
        // สร้าง Switch ไว้ที่ Accessory View ของแต่ละแถว
        let switchView = UISwitch()
        switchView.isOn = isEnabled
        switchView.tag = indexPath.row
        switchView.addTarget(self, action: #selector(switchChanged(_:)), for: .valueChanged)
        cell?.accessoryView = switchView
        
        return cell!
    }
    
    // รองรับการปัดซ้ายเพื่อลบแถว
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            featureList.remove(at: indexPath.row)
            saveFeaturesToJson()
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
}
