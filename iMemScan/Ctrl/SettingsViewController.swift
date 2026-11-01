//
//  SettingsViewController.swift
//  iMemScan
//
//  Created by Custom on 2026.
//

import UIKit

// ประกาศ Private API ลับเพื่อให้สามารถดึงไอคอนของจริงมาแสดงผลได้
extension UIImage {
    @objc class func _applicationIconImage(forBundleIdentifier bundleIdentifier: String, format: Int32, scale: CGFloat) -> UIImage? {
        return nil
    }
}

class SettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    private var tableView: UITableView!
    private let sectionTitles = ["เกี่ยวกับ", "เครดิตร"]
    private var tableData: [String: [[String: String]]] = [:]

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let backButton = UIBarButtonItem(title: "TrollMemScan", style: .plain, target: nil, action: nil)
        self.navigationController?.navigationBar.topItem?.backBarButtonItem = backButton
        self.navigationController?.navigationBar.tintColor = .white

        // ตั้งค่า Title ให้เป็นอักษรตัวใหญ่ชิดซ้ายบน (Large Title)
        self.title = "การตั้งค่า"
        if let navigationController = self.navigationController {
            navigationController.navigationBar.prefersLargeTitles = true
            self.navigationItem.largeTitleDisplayMode = .always
        }
        
        self.view.backgroundColor = .systemBackground
        
        let infoPlist = Bundle.main.infoDictionary ?? [:]
        let appName = (infoPlist["CFBundleDisplayName"] as? String) ?? ((infoPlist["CFBundleName"] as? String) ?? "Application")
        let bundleID = Bundle.main.bundleIdentifier ?? "com.example.app"
        let version = (infoPlist["CFBundleShortVersionString"] as? String) ?? "1.0"
        
        // ดึงวันเวลาคอมไพล์จาก Compiler Macro มาตรฐานอัตโนมัติ
        let compileDate = String(validatingUTF8: __DATE__) ?? ""
        let compileTime = String(validatingUTF8: __TIME__) ?? ""
        let buildTimeStr = "\(compileDate) \(compileTime)"
        
        let fullVersion = "v\(version) (\(buildTimeStr))"
        
        // กำหนด Bundle ID ของแอปที่ต้องการดึงไอคอนมาแสดงในส่วนเครดิต
        let creditAppBundleID = "ph.telegra.Telegraph"
        
        tableData = [
            "เกี่ยวกับ": [
                ["title": appName, "bundle": bundleID, "version": fullVersion, "build_time": buildTimeStr]
            ],
            "เครดิตร": [
                ["title": "F1X3R", "subtitle_val": "นักพัฒนาจากทีม TGS", "bundle": creditAppBundleID]
            ]
        ]
        
        tableView = UITableView(frame: view.bounds, style: .insetGrouped)
        tableView.backgroundColor = .systemGroupedBackground
        tableView.separatorColor = .separator
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    // MARK: - Table View Data Source

    func numberOfSections(in tableView: UITableView) -> Int {
        return sectionTitles.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionTitle = sectionTitles[section]
        return tableData[sectionTitle]?.count ?? 0
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionTitles[section]
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let sectionTitle = sectionTitles[indexPath.section]
        guard let rowData = tableData[sectionTitle]?[indexPath.row] else {
            return UITableViewCell()
        }
        
        let cellIdentifier = (indexPath.section == 0) ? @"SingleAppInfoCell" : @"StandardSettingsCell"
        var cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
        
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: cellIdentifier)
        }
        
        // ตั้งค่าสไตล์พื้นหลังธีมมืด
        cell?.backgroundColor = .secondarySystemGroupedBackground
        cell?.selectionStyle = .none
        cell?.accessoryType = .none
        cell?.accessoryView = nil
        
        if indexPath.section == 0 {
            // 1. ชื่อแอป
            cell?.textLabel?.text = rowData["title"]
            cell?.textLabel?.textColor = .label
            
            // 2. Version และ Build Time
            cell?.detailTextLabel?.text = rowData["version"]
            cell?.detailTextLabel?.textColor = .secondaryLabel
            
            // 3. ดึงไอคอนแอปหลักผ่าน Private API
            var appIcon: UIImage? = nil
            if let currentBID = rowData["bundle"] {
                let selector = NSSelectorFromString("_applicationIconImageForBundleIdentifier:format:scale:")
                if UIImage.responds(to: selector) {
                    let imp = UIImage.method(for: selector)
                    typealias IconFunc = @convention(c) (AnyClass, Selector, String, Int32, CGFloat) -> UIImage?
                    let iconMethod = unsafeBitCast(imp, to: IconFunc.self)
                    appIcon = iconMethod(UIImage.self, selector, currentBID, 0, UIScreen.main.scale)
                }
            }
            
            if let icon = appIcon {
                cell?.imageView?.image = icon
                cell?.imageView?.tintColor = nil
            } else {
                if #available(iOS 14.0, *) {
                    cell?.imageView?.image = UIImage(systemName: "app.window.checkmark")
                    cell?.imageView?.tintColor = .label
                }
            }
            
        } else {
            // เซกชันเครดิตร
            cell?.textLabel?.text = rowData["title"]
            cell?.textLabel?.textColor = .label
            
            cell?.detailTextLabel?.text = rowData["subtitle_val"]
            cell?.detailTextLabel?.textColor = .secondaryLabel
            
            // ดึงไอคอนผ่าน Private API สำหรับแสดงผลทางซ้าย
            var creditIcon: UIImage? = nil
            if let creditBID = rowData["bundle"] {
                let selector = NSSelectorFromString("_applicationIconImageForBundleIdentifier:format:scale:")
                if UIImage.responds(to: selector) {
                    let imp = UIImage.method(for: selector)
                    typealias IconFunc = @convention(c) (AnyClass, Selector, String, Int32, CGFloat) -> UIImage?
                    let iconMethod = unsafeBitCast(imp, to: IconFunc.self)
                    creditIcon = iconMethod(UIImage.self, selector, creditBID, 0, UIScreen.main.scale)
                }
            }
            
            if let icon = creditIcon {
                cell?.imageView?.image = icon
                cell?.imageView?.tintColor = nil
            } else {
                cell?.imageView?.image = nil
            }
            
            if rowData["subtitle_val"] == "นักพัฒนาจากทีม TGS" {
                cell?.selectionStyle = .default
            }
        }
        
        return cell ?? UITableViewCell()
    }

    // MARK: - Table View Delegate

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let header = view as? UITableViewHeaderFooterView {
            header.textLabel?.textColor = .secondaryLabel
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return (indexPath.section == 0) ? 65.0 : 60.0
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let sectionTitle = sectionTitles[indexPath.section]
        guard let rowData = tableData[sectionTitle]?[indexPath.row] else { return }
        
        if rowData["subtitle_val"] == "นักพัฒนาจากทีม TGS" {
            if let telegramURL = URL(string: "tg://user?id=6105731078") {
                if UIApplication.shared.canOpenURL(telegramURL) {
                    UIApplication.shared.open(telegramURL, options: [:], completionHandler: nil)
                }
            }
        }
    }
}
