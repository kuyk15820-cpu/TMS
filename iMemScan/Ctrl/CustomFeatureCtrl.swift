//
//  CustomFeatureCtrl.swift
//  iMemScan
//
//  Created by Custom on 2026.
//

import UIKit
import SwiftUI
import UniformTypeIdentifiers

// Model สำหรับจัดการข้อมูลฟีเจอร์ (ไม่บันทึก isEnabled ลง JSON)
struct ScriptFeature: Identifiable, Codable {
    var id = UUID()
    var name: String
    var originalValue: String = ""
    var modifiedValue: String = ""
    var isSaved: Bool = false
    var isEnabled: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case name, originalValue, modifiedValue, isSaved
    }
    
    init(id: UUID = UUID(), name: String, originalValue: String = "", modifiedValue: String = "", isSaved: Bool = false, isEnabled: Bool = false) {
        self.id = id
        self.name = name
        self.originalValue = originalValue
        self.modifiedValue = modifiedValue
        self.isSaved = isSaved
        self.isEnabled = isEnabled
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        originalValue = try container.decodeIfPresent(String.self, forKey: .originalValue) ?? ""
        modifiedValue = try container.decodeIfPresent(String.self, forKey: .modifiedValue) ?? ""
        isSaved = try container.decodeIfPresent(Bool.self, forKey: .isSaved) ?? false
        isEnabled = false // 🟢 บังคับให้เป็น false เสมอเมื่อเปิดแอปใหม่ ไม่จำสถานะเปิด/ปิด
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(originalValue, forKey: .originalValue)
        try container.encode(modifiedValue, forKey: .modifiedValue)
        try container.encode(isSaved, forKey: .isSaved)
        // ไม่ทำการ encode ค่า isEnabled เพื่อไม่ให้จำสถานะเปิด/ปิด
    }
}

// ViewModel เพื่อใช้แชร์สถานะระหว่าง UIKit และ SwiftUI ได้อย่างแม่นยำ
class ScriptManagerViewModel: ObservableObject {
    @Published var features: [ScriptFeature] = []
    @Published var showingAddAlert: Bool = false
    @Published var processingFeatureID: UUID? = nil
    
    // 🟢 ข้อมูลแอปเป้าหมายปัจจุบัน
    @Published var targetApp: TargetGameApp = TargetGameApp(name: "Free Fire", bundleID: "com.dts.freefireth", active: true)
    @Published var currentPID: Int32? = nil
    @Published var isAppRunning: Bool = false
    @Published var isAppInstalled: Bool = true
    
    var scrollToProxy: ScrollViewProxy?
    weak var parentVC: CustomFeatureCtrl?
    
    func scrollToBottom() {
        if let lastID = features.last?.id {
            withAnimation {
                scrollToProxy?.scrollTo(lastID, anchor: .bottom)
            }
        }
    }
    
    // 🟢 ตรวจสอบสถานะการติดตั้งแอปผ่าน LSApplicationWorkspace แบบแม่นยำ
    func checkAppInstallation() {
        isAppInstalled = false
        if let workspaceClass = NSClassFromString("LSApplicationWorkspace") as? NSObject.Type,
           let workspace = workspaceClass.perform(Selector(("defaultWorkspace")))?.takeUnretainedValue() as? NSObject {
            
            if let installedApps = workspace.perform(Selector(("allInstalledApplications")))?.takeUnretainedValue() as? [NSObject] {
                for app in installedApps {
                    if let appBundleID = app.perform(Selector(("applicationIdentifier")))?.takeUnretainedValue() as? String,
                       appBundleID.lowercased() == targetApp.bundleID.lowercased() {
                        isAppInstalled = true
                        break
                    }
                }
            }
        }
    }
    
    // 🟢 ตรวจสอบสถานะ Process และ PID ให้ตรงเป๊ะ ป้องกันการจับโปรเซสผิดพลาด
    func refreshTargetStatus() {
        checkAppInstallation()
        
        currentPID = nil
        isAppRunning = false
        
        guard isAppInstalled else { return }
        guard let sections = PidModel.refreshModelArray() as? [[PidModel]] else { return }
        
        let targetName = targetApp.name.lowercased()
        let targetBundle = targetApp.bundleID.lowercased()
        
        for section in sections {
            for model in section {
                let modelName = model.name.lowercased()
                if modelName == targetName || modelName.contains(targetBundle) || (modelName.contains(targetName) && targetName.count > 3) {
                    if let pidInt = Int32(model.pid), pidInt > 0 {
                        currentPID = pidInt
                        isAppRunning = true
                        VMTool.share().setPid(pidInt, name: model.name)
                        return
                    }
                }
            }
        }
    }
}

class CustomFeatureCtrl: UIViewController {

    var viewModel = ScriptManagerViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "TrollMemScan"
        view.backgroundColor = .systemBackground
        
        viewModel.parentVC = self
        
        let scriptView = ScriptManagerView(viewModel: viewModel)
        let hostingController = UIHostingController(rootView: scriptView)
        addChild(hostingController)
        hostingController.view.frame = view.bounds
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
        
        updateNavigationButton()
        viewModel.refreshTargetStatus()
        
        // 🟢 ดักจับเหตุการณ์เมื่อแอปกลับมาทำงานหน้าจอหลัก (Foreground)
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.viewModel.refreshTargetStatus()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.refreshTargetStatus()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    func updateNavigationButton() {
        let addBtn = UIBarButtonItem(image: UIImage(systemName: "plus"), style: .plain, target: self, action: #selector(didTapAddButton))
        navigationItem.rightBarButtonItems = [addBtn]
    }

    @objc func didTapAddButton() {
        viewModel.showingAddAlert = true
    }
    
    func showSuccessNotification(message: String) {
        let icon = UIImage(systemName: "checkmark.circle")?.withTintColor(.white, renderingMode: .alwaysOriginal)
        FTNotificationIndicator.setNotificationIndicatorStyle(.dark)
        FTNotificationIndicator.showNotification(
            with: icon,
            title: "สำเร็จ",
            message: message
        )
    }

    func showErrorNotification(message: String) {
        let icon = UIImage(systemName: "exclamationmark.triangle")?.withTintColor(.white, renderingMode: .alwaysOriginal)
        FTNotificationIndicator.setNotificationIndicatorStyle(.dark)
        FTNotificationIndicator.showNotification(
            with: icon,
            title: "ล้มเหลว",
            message: message
        )
    }
    
    func showValueInputAlert(title: String, message: String, initialValue: String, completion: @escaping (String) -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        var targetTextField: UITextField?
        
        alert.addTextField { textField in
            textField.placeholder = "เช่น 909000001 (อย่างน้อย 9 หลัก)"
            textField.text = initialValue
            textField.keyboardType = .numberPad
            textField.clearButtonMode = .whileEditing
            targetTextField = textField
        }
        
        let saveAction = UIAlertAction(title: "ตกลง", style: .default) { _ in
            if let text = targetTextField?.text {
                completion(text)
            }
        }
        let cancelAction = UIAlertAction(title: "ยกเลิก", style: .cancel, handler: nil)
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
}

// 🟢 การ์ดแสดงสถานะแอปเป้าหมาย
struct TargetAppStatusCard: View {
    @ObservedObject var viewModel: ScriptManagerViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                if let icon = viewModel.targetApp.icon {
                    Image(uiImage: icon)
                        .resizable()
                        .frame(width: 50, height: 50)
                        .cornerRadius(10)
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.secondary.opacity(0.3))
                        .frame(width: 50, height: 50)
                        .overlay(Image(systemName: "app.fill").foregroundColor(.secondary))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.targetApp.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(viewModel.targetApp.bundleID)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(!viewModel.isAppInstalled ? Color.red : (viewModel.isAppRunning ? Color.green : Color.orange))
                            .frame(width: 8, height: 8)
                        
                        Text(!viewModel.isAppInstalled ? "Not Installed" : (viewModel.isAppRunning ? "Running (PID: \(viewModel.currentPID ?? 0))" : "Not Running"))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(!viewModel.isAppInstalled ? .red : (viewModel.isAppRunning ? .green : .orange))
                    }
                }
                
                Spacer()
            }
            
            Divider()
            
            Button(action: {
                guard viewModel.isAppInstalled else {
                    viewModel.parentVC?.showErrorNotification(message: "ไม่ได้ติดตั้งแอปพลิเคชันนี้บนเครื่อง")
                    return
                }
                let success = AppLauncher.launchApp(bundleID: viewModel.targetApp.bundleID)
                if success {
                    viewModel.parentVC?.showSuccessNotification(message: "กำลังเปิด \(viewModel.targetApp.name)...")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        viewModel.refreshTargetStatus()
                    }
                } else {
                    viewModel.parentVC?.showErrorNotification(message: "ไม่สามารถเปิดแอปได้")
                }
            }) {
                Label("เปิดแอป", systemImage: "play")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal)
        .onAppear {
            viewModel.refreshTargetStatus()
        }
    }
}

struct OutlinedValueView: View {
    let title: String
    let value: String
    let placeholder: String
    var isDisabled: Bool = false
    var onTap: () -> Void
    
    var body: some View {
        ZStack(alignment: .leading) {
            HStack(spacing: 8) {
                Text(value.isEmpty ? placeholder : value)
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(value.isEmpty ? .secondary.opacity(0.7) : .primary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if !isDisabled {
                            onTap()
                        }
                    }
            }
            .padding(.horizontal, 12)
            .frame(height: 48)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isDisabled ? Color.secondary.opacity(0.2) : Color.secondary.opacity(0.5), lineWidth: 1)
            )
            .background(isDisabled ? Color(.systemGray6).opacity(0.5) : Color.clear)
            .cornerRadius(8)
            
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
                .background(Color(.systemBackground))
                .offset(x: 10, y: -24)
        }
        .padding(.top, 12)
    }
}

struct FeatureCardView: View {
    @Binding var feature: ScriptFeature
    @ObservedObject var viewModel: ScriptManagerViewModel
    var onDelete: () -> Void
    var onAction: () -> Void
    var onEditOriginal: () -> Void
    var onEditModified: () -> Void
    
    var isLoading: Bool {
        viewModel.processingFeatureID == feature.id
    }
    
    var isAnyOtherLoading: Bool {
        viewModel.processingFeatureID != nil && viewModel.processingFeatureID != feature.id
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(feature.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Menu {
                    Button(role: .destructive, action: {
                        onDelete()
                    }) {
                        Label("ลบฟีเจอร์นี้", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(6)
                }
            }
            
            VStack(spacing: 14) {
                OutlinedValueView(
                    title: "ค่าต้นฉบับ",
                    value: feature.originalValue,
                    placeholder: "แตะเพื่อกรอกค่าต้นฉบับ...",
                    isDisabled: feature.isSaved || isLoading || isAnyOtherLoading,
                    onTap: onEditOriginal
                )
                
                OutlinedValueView(
                    title: "ค่าที่ต้องการแก้ไข",
                    value: feature.modifiedValue,
                    placeholder: "แตะเพื่อกรอกค่าที่ต้องการแก้ไข...",
                    isDisabled: feature.isSaved || isLoading || isAnyOtherLoading,
                    onTap: onEditModified
                )
            }
            .padding(.horizontal, 4)
            
            // 🟢 ใช้สีฟ้า (Color.accentColor) ตอนกำลังประมวลผล และบังคับ Opacity = 1.0 เสมอ ไม่ให้จางตอนกดค้าง
            Button(action: {
                onAction()
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isLoading ? Color.accentColor : buttonBackgroundColor)
                        .frame(height: 40)
                    
                    Text(isLoading ? "กำลังประมวลผล..." : buttonTitle)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .disabled(isLoading || isAnyOtherLoading || (!feature.isSaved && (feature.originalValue.count < 9 || feature.modifiedValue.count < 9)))
            .opacity(1.0)
            .buttonStyle(PlainButtonStyle())
            .transaction { transaction in
                transaction.disablesAnimations = true
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal)
    }
    
    var buttonTitle: String {
        if !feature.isSaved {
            return "บันทึก"
        } else {
            return feature.isEnabled ? "ปิดใช้งาน" : "เปิดใช้งาน"
        }
    }
    
    var buttonBackgroundColor: Color {
        if !feature.isSaved {
            return Color.orange
        } else {
            return feature.isEnabled ? Color.red : Color.accentColor
        }
    }
}

struct ScriptManagerView: View {
    @ObservedObject var viewModel: ScriptManagerViewModel
    @State private var newName = ""
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 16) {
                    TargetAppStatusCard(viewModel: viewModel)
                        .padding(.top, 8)
                    
                    LazyVStack(spacing: 16) {
                        ForEach($viewModel.features) { $feature in
                            FeatureCardView(
                                feature: $feature,
                                viewModel: viewModel,
                                onDelete: {
                                    if let index = viewModel.features.firstIndex(where: { $0.id == feature.id }) {
                                        viewModel.features.remove(at: index)
                                        saveToJson()
                                    }
                                },
                                onAction: {
                                    handleButtonAction(for: &feature)
                                },
                                onEditOriginal: {
                                    viewModel.parentVC?.showValueInputAlert(
                                        title: "ค่าต้นฉบับ",
                                        message: "กรอกค่าต้นฉบับ อย่างน้อย 9 หลัก",
                                        initialValue: feature.originalValue
                                    ) { newValue in
                                        feature.originalValue = newValue
                                        saveToJson()
                                    }
                                },
                                onEditModified: {
                                    viewModel.parentVC?.showValueInputAlert(
                                        title: "ค่าที่ต้องการแก้ไข",
                                        message: "กรอกค่าที่ต้องการแก้ไข อย่างน้อย 9 หลัก",
                                        initialValue: feature.modifiedValue
                                    ) { newValue in
                                        feature.modifiedValue = newValue
                                        saveToJson()
                                    }
                                }
                            )
                            .id(feature.id)
                        }
                    }
                }
                .padding(.vertical)
            }
            .onAppear {
                viewModel.scrollToProxy = proxy
                loadFromJson()
                viewModel.refreshTargetStatus()
            }
            .alert("เพิ่มฟีเจอร์ใหม่", isPresented: $viewModel.showingAddAlert) {
                TextField("ชื่อฟีเจอร์ เช่น ?", text: $newName)
                Button("เพิ่ม") {
                    let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                    if trimmedName.isEmpty {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            viewModel.showingAddAlert = true
                        }
                    } else {
                        let newFeature = ScriptFeature(name: trimmedName, originalValue: "", modifiedValue: "", isSaved: false, isEnabled: false)
                        viewModel.features.append(newFeature)
                        saveToJson()
                        newName = ""
                        viewModel.scrollToBottom()
                    }
                }
                
                Button("ยกเลิก", role: .cancel) {
                    newName = ""
                }
            } message: {
                Text(newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && viewModel.showingAddAlert ? "กรอกชื่อฟีเจอร์ใหม่ของคุณ" : "Enter a name for your custom I32 feature.")
            }
        }
    }
    
    func handleButtonAction(for feature: inout ScriptFeature) {
        if !feature.isSaved {
            if feature.originalValue.count >= 9 && feature.modifiedValue.count >= 9 {
                feature.isSaved = true
                saveToJson() // 🟢 เพิ่มการเรียกบันทึกทันทีเมื่อกดปุ่ม Save สำเร็จ เพื่อให้อัปเดตข้อมูลทุกฟีเจอร์ลงไฟล์ JSON ทันที
            }
        } else {
            viewModel.refreshTargetStatus()
            
            guard viewModel.isAppInstalled else {
                viewModel.parentVC?.showErrorNotification(message: "ไม่ได้ติดตั้งแอปพลิเคชัน")
                return
            }
            
            guard viewModel.isAppRunning else {
                viewModel.parentVC?.showErrorNotification(message: "ไม่ได้เปิดแอป กรุณาเปิดแอปก่อนเปิดใช้งานฟีเจอร์")
                return
            }
            
            viewModel.processingFeatureID = feature.id
            
            let targetEnableState = !feature.isEnabled
            executeVMTool(feature: feature, isApply: targetEnableState)
        }
    }
    
    func executeVMTool(feature: ScriptFeature, isApply: Bool) {
        let valueType = VMMemValueType(rawValue: VMMemValueType.RawValue(VMMemValueTypeSignedInt.rawValue))
        let comparison = VMMemComparisonEQ
        
        let searchVal = isApply ? feature.originalValue : feature.modifiedValue
        let targetVal = isApply ? feature.modifiedValue : feature.originalValue
        
        print("Executing -> Search \(searchVal) (I32) -> Edit to \(targetVal) (I32)")
        
        VMTool.share().searchValue(searchVal, type: valueType, comparison: comparison) { count, array in
            DispatchQueue.main.async {
                self.viewModel.processingFeatureID = nil
                
                if count > 0 {
                    for model in array {
                        if let memModel = model as? MemModel {
                            memModel.value = targetVal
                            memModel.type = valueType
                            VMTool.share().modifyValue(targetVal, address: memModel.address, type: valueType)
                        }
                    }
                    
                    if let index = self.viewModel.features.firstIndex(where: { $0.id == feature.id }) {
                        self.viewModel.features[index].isEnabled = isApply
                    }
                    
                    let actionText = isApply ? "Enabled" : "Disabled"
                    viewModel.parentVC?.showSuccessNotification(message: "\(feature.name) successfully \(actionText) (\n\(count) addresses)")
                } else {
                    viewModel.parentVC?.showErrorNotification(message: "ไม่พบค่า (\(searchVal)) ของฟีเจอร์ \(feature.name)")
                }
                VMTool.share().reset()
            }
        }
    }
    
    func getJSONFileURL() -> URL {
        let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let trollDir = docDir.appendingPathComponent("TrollMemScan")
        if !FileManager.default.fileExists(atPath: trollDir.path) {
            try? FileManager.default.createDirectory(at: trollDir, withIntermediateDirectories: true)
        }
        return trollDir.appendingPathComponent("trollmemscan.json")
    }
    
    func saveToJson() {
        let url = getJSONFileURL()
        do {
            let data = try JSONEncoder().encode(viewModel.features)
            try data.write(to: url)
        } catch {
            print("Failed to save JSON: \(error)")
        }
    }
    
    func loadFromJson() {
        let url = getJSONFileURL()
        guard let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([ScriptFeature].self, from: data) else { return }
        viewModel.features = decoded
    }
}

