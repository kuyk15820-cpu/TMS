//
//  CustomFeatureCtrl.swift
//  iMemScan
//
//  Created by Custom on 2026.
//

import UIKit
import SwiftUI
import UniformTypeIdentifiers

// Model สำหรับจัดการข้อมูลฟีเจอร์ (รองรับ Codable สำหรับ JSON แต่ไม่บันทึก isEnabled)
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
        isEnabled = false // รีเซ็ตสถานะเปิด/ปิดเป็น false เสมอเมื่อโหลดขึ้นมาใหม่
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(originalValue, forKey: .originalValue)
        try container.encode(modifiedValue, forKey: .modifiedValue)
        try container.encode(isSaved, forKey: .isSaved)
    }
}

// ViewModel เพื่อใช้แชร์สถานะระหว่าง UIKit และ SwiftUI ได้อย่างแม่นยำ
class ScriptManagerViewModel: ObservableObject {
    @Published var features: [ScriptFeature] = []
    @Published var showingAddAlert: Bool = false
    @Published var isEditingAnyField: Bool = false
    
    // 🟢 ตัวแปรเปิด/ปิดเพื่อบังคับให้ SwiftUI วาด Layout ของ ScrollView ใหม่
    @Published var keyboardTrigger: Bool = false
    
    var scrollToProxy: ScrollViewProxy?
    weak var parentVC: CustomFeatureCtrl?
    
    func updateEditingState() {
        DispatchQueue.main.async {
            self.parentVC?.updateNavigationButtons(isEditingField: self.isEditingAnyField)
        }
    }
    
    func scrollToBottom() {
        if let lastID = features.last?.id {
            withAnimation {
                scrollToProxy?.scrollTo(lastID, anchor: .bottom)
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
        
        updateNavigationButtons(isEditingField: false)
        
        // 🟢 ลงทะเบียนฟังสถานะตอนคีย์บอร์ดกำลังจะปิด เพื่อบังคับเคลียร์ช่องว่างค้างด้านล่าง
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc func keyboardWillHide() {
        DispatchQueue.main.async {
            // สลับสถานะตัวแปรเพื่อให้ ScrollView ใน SwiftUI ทำการ Re-render พื้นที่ใหม่ทันที
            self.viewModel.keyboardTrigger.toggle()
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
        }
    }

    // จัดการแสดงปุ่มบนขวา: ปุ่ม + อยู่ขวาบนสุดเสมอ, ถ้าพิมพ์อยู่จะมีปุ่ม "เสร็จสิ้น" เลื่อนมาอยู่ทางซ้าย
    func updateNavigationButtons(isEditingField: Bool) {
        let addBtn = UIBarButtonItem(image: UIImage(systemName: "plus.circle.fill"), style: .plain, target: self, action: #selector(didTapAddButton))
        
        if isEditingField {
            let doneBtn = UIBarButtonItem(title: "เสร็จสิ้น", style: .done, target: self, action: #selector(didTapDoneButton))
            navigationItem.rightBarButtonItems = [doneBtn, addBtn]
        } else {
            navigationItem.rightBarButtonItems = [addBtn]
        }
    }

    @objc func didTapAddButton() {
        viewModel.showingAddAlert = true
    }

    @objc func didTapDoneButton() {
        view.endEditing(true) // ปิดคีย์บอร์ดทั้งหมด
        viewModel.isEditingAnyField = false
        updateNavigationButtons(isEditingField: false)
    }
}

// Custom Outlined Text Field UI
struct OutlinedTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var isDisabled: Bool = false
    @ObservedObject var viewModel: ScriptManagerViewModel
    @FocusState var isFocused: Bool
    
    var body: some View {
        ZStack(alignment: .leading) {
            HStack(spacing: 8) {
                TextField(placeholder, text: $text)
                    .keyboardType(.numberPad)
                    .font(.system(size: 14, design: .monospaced))
                    .focused($isFocused)
                    .disabled(isDisabled)
                    .onChange(of: isFocused) { focused in
                        if focused {
                            viewModel.isEditingAnyField = true
                            viewModel.updateEditingState()
                        }
                    }
                
                // ปุ่มสลับสถานะ: ถ้ามีข้อความแสดงปุ่ม Clear (xmark), ถ้าว่างแสดงปุ่ม Paste
                if !isDisabled {
                    Button(action: {
                        if !text.isEmpty {
                            text = ""
                        } else {
                            if let clipboardString = UIPasteboard.general.string {
                                text = clipboardString
                            }
                        }
                    }) {
                        Image(systemName: !text.isEmpty ? "xmark.circle.fill" : "doc.on.clipboard")
                            .foregroundColor(.secondary)
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
            
            // ป้ายชื่อลอยทับขอบด้านบน
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

// Sub-view สำหรับการ์ดแต่ละรายการ
struct FeatureCardView: View {
    @Binding var feature: ScriptFeature
    @ObservedObject var viewModel: ScriptManagerViewModel
    var onDelete: () -> Void
    var onAction: () -> Void
    var onSaveChange: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // ส่วนหัวการ์ด: ชื่อฟีเจอร์ และ เมนูสามจุดด้านขวา
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
            
            // ช่องกรอก Original และ Modified แบบ Outlined TextField
            VStack(spacing: 14) {
                OutlinedTextField(title: "ORIGINAL (I32)", placeholder: "909000004 (อย่างน้อย 9 หลัก)", text: $feature.originalValue, isDisabled: feature.isSaved, viewModel: viewModel)
                    .onChange(of: feature.originalValue) { _ in
                        if !feature.isSaved { onSaveChange() }
                    }
                
                OutlinedTextField(title: "MODIFIED (I32)", placeholder: "909040010 (อย่างน้อย 9 หลัก)", text: $feature.modifiedValue, isDisabled: feature.isSaved, viewModel: viewModel)
                    .onChange(of: feature.modifiedValue) { _ in
                        if !feature.isSaved { onSaveChange() }
                    }
            }
            .padding(.horizontal, 4)
            
            // ปุ่มทำงานปุ่มเดียว (สลับระหว่าง Save / Enable / Disable)
            Button(action: {
                onAction()
            }) {
                Text(buttonTitle)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(buttonBackgroundColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .disabled(!feature.isSaved && (feature.originalValue.count < 9 || feature.modifiedValue.count < 9))
            .opacity((!feature.isSaved && (feature.originalValue.count < 9 || feature.modifiedValue.count < 9)) ? 0.5 : 1.0)
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
            return "Save"
        } else {
            return feature.isEnabled ? "Disable" : "Enable"
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

// SwiftUI Implementation with Custom UI Design
struct ScriptManagerView: View {
    @ObservedObject var viewModel: ScriptManagerViewModel
    @State private var newName = ""
    
    var totalCount: Int { viewModel.features.count }
    var activeCount: Int { viewModel.features.filter { $0.isEnabled }.count }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 16) {
                    // แคปซูลแสดงแถบสถานะ
                    HStack(spacing: 8) {
                        Image(systemName: "cpu")
                            .foregroundColor(.accentColor)
                        Text("รายการฟีเจอร์: \(totalCount)")
                        Text("|")
                            .foregroundColor(.secondary)
                        Text("ใช้งานอยู่: \(activeCount)")
                            .foregroundColor(activeCount > 0 ? .green : .secondary)
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(Capsule())
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
                                onSaveChange: {
                                    saveToJson()
                                }
                            )
                            .id(feature.id)
                        }
                    }
                }
                .padding(.vertical)
            }
            // 🟢 ผูก ID เข้ากับ keyboardTrigger เพื่อบังคับเคลียร์พื้นที่ว่างเมื่อคีย์บอร์ดปิด
            .id(viewModel.keyboardTrigger)
            .onAppear {
                viewModel.scrollToProxy = proxy
                loadFromJson()
            }
            .alert("Add Script Feature", isPresented: $viewModel.showingAddAlert) {
                TextField("Feature Name (e.g. GodMode)", text: $newName)
                Button("Add") {
                    let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                    if trimmedName.isEmpty {
                        // ถ้าไม่ได้กรอกชื่อ ให้เด้ง Alert เปิดซ้ำเพื่อให้กรอกใหม่ทันที
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            viewModel.showingAddAlert = true
                        }
                    } else {
                        let newFeature = ScriptFeature(name: trimmedName, originalValue: "", modifiedValue: "", isSaved: false, isEnabled: false)
                        viewModel.features.append(newFeature)
                        saveToJson()
                        newName = ""
                        
                        // เลื่อนหน้าจอลงไปที่การ์ดล่าสุดเฉพาะตอนเพิ่มฟีเจอร์ใหม่
                        viewModel.scrollToBottom()
                    }
                }
                
                Button("Cancel", role: .cancel) {
                    newName = ""
                }
            } message: {
                Text(newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && viewModel.showingAddAlert ? "กรุณากรอกชื่อฟีเจอร์ก่อนกด Add" : "Enter a name for your custom I32 feature.")
            }
        }
    }
    
    func handleButtonAction(for feature: inout ScriptFeature) {
        if !feature.isSaved {
            if feature.originalValue.count >= 9 && feature.modifiedValue.count >= 9 {
                feature.isSaved = true
                saveToJson()
            }
        } else {
            feature.isEnabled.toggle()
            saveToJson()
            executeVMTool(original: feature.originalValue, modified: feature.modifiedValue, isApply: feature.isEnabled)
        }
    }
    
    // MARK: - ทำงานจริงผ่าน VMTool สไตล์ H5GG
    func executeVMTool(original: String, modified: String, isApply: Bool) {
        let valueType = VMMemValueType(rawValue: VMMemValueType.RawValue(VMMemValueTypeSignedInt.rawValue))
        let comparison = VMMemComparisonEQ
        
        let searchVal = isApply ? original : modified
        let targetVal = isApply ? modified : original
        
        print("Executing -> Search \(searchVal) (I32) -> Edit to \(targetVal) (I32)")
        
        VMTool.share().searchValue(searchVal, type: valueType, comparison: comparison) { count, array in
            if count > 0 {
                for model in array {
                    if let memModel = model as? MemModel {
                        memModel.value = targetVal
                        memModel.type = valueType
                        VMTool.share().modifyValue(targetVal, address: memModel.address, type: valueType)
                    }
                }
            }
            VMTool.share().reset()
        }
    }
    
    // MARK: - จัดการ JSON ใน Application Support (ไม่บันทึกสถานะ isEnabled)
    func getJSONFileURL() -> URL {
        let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let supportDir = paths[0]
        if !FileManager.default.fileExists(atPath: supportDir.path) {
            try? FileManager.default.createDirectory(at: supportDir, withIntermediateDirectories: true)
        }
        return supportDir.appendingPathComponent("swiftui_h5gg_features.json")
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
