//
//  CustomFeatureCtrl.swift
//  iMemScan
//
//  Created by Custom on 2026.
//

import UIKit
import SwiftUI

// Model สำหรับจัดการข้อมูลฟีเจอร์ (รองรับ Codable สำหรับ JSON)
struct ScriptFeature: Identifiable, Codable {
    var id = UUID()
    var name: String
    var originalValue: String
    var modifiedValue: String
    var isSaved: Bool = false
    var isEnabled: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case name, originalValue, modifiedValue, isSaved, isEnabled
    }
}

class CustomFeatureCtrl: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "H5GG Script Manager (I32)"
        view.backgroundColor = .systemBackground
        
        // ฝัง SwiftUI View เข้ามาใน UIViewController
        let hostingController = UIHostingController(rootView: ScriptManagerView())
        addChild(hostingController)
        hostingController.view.frame = view.bounds
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
    }
}

// Custom Outlined Text Field UI (สไตล์กรอบมีป้ายชื่อทับเส้นขอบตามรูปตัวอย่าง)
struct OutlinedTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        ZStack(alignment: .leading) {
            TextField(placeholder, text: $text)
                .keyboardType(.numberPad)
                .font(.system(size: 14, design: .monospaced))
                .padding(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.5), lineWidth: 1)
                )
            
            // ป้ายชื่อลอยทับขอบด้านบน
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
                .background(Color(.systemBackground))
                .offset(x: 10, y: -20)
        }
        .padding(.top, 8)
    }
}

// SwiftUI Implementation with Custom UI Design
struct ScriptManagerView: View {
    @State private var features: [ScriptFeature] = []
    @State private var showingAddAlert = false
    @State private var newName = ""
    
    // คำนวณจำนวนฟีเจอร์ทั้งหมด และจำนวนที่เปิดใช้งานอยู่
    var totalCount: Int { features.count }
    var activeCount: Int { features.filter { $0.isEnabled }.count }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // แคปซูลแสดงแถบสถานะ (Capsule Status Header)
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
                        ForEach($features) { $feature in
                            VStack(alignment: .leading, spacing: 14) {
                                // ชื่อฟีเจอร์
                                Text(feature.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                // ช่องกรอก Original และ Modified แบบ Outlined TextField
                                VStack(spacing: 14) {
                                    OutlinedTextField(title: "ORIGINAL (I32)", placeholder: "909000004", text: $feature.originalValue)
                                        .onChange(of: feature.originalValue) { _ in
                                            feature.isSaved = false
                                            saveToJson()
                                        }
                                    
                                    OutlinedTextField(title: "MODIFIED (I32)", placeholder: "909040010", text: $feature.modifiedValue)
                                        .onChange(of: feature.modifiedValue) { _ in
                                            feature.isSaved = false
                                            saveToJson()
                                        }
                                }
                                .padding(.horizontal, 4)
                                
                                // ปุ่มทำงานปุ่มเดียว (สลับระหว่าง Save / Enable / Disable)
                                Button(action: {
                                    handleButtonAction(for: &feature)
                                }) {
                                    Text(buttonTitle(for: feature))
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(buttonBackgroundColor(for: feature))
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
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
                        .onDelete(perform: deleteItems)
                    }
                }
                .padding(.vertical)
            }
            .navigationBarItems(trailing: Button(action: {
                showingAddAlert = true
            }) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
            })
            .alert("Add Script Feature", isPresented: $showingAddAlert) {
                TextField("Feature Name (e.g. GodMode)", text: $newName)
                Button("Add") {
                    if !newName.isEmpty {
                        let newFeature = ScriptFeature(name: newName, originalValue: "", modifiedValue: "", isSaved: false, isEnabled: false)
                        features.append(newFeature)
                        saveToJson()
                        newName = ""
                    }
                }
                Button("Cancel", role: .cancel) { newName = "" }
            } message: {
                Text("Enter a name for your custom I32 feature.")
            }
            .onAppear {
                loadFromJson()
            }
        }
    }
    
    // กำหนดข้อความปุ่มตามสถานะ
    func buttonTitle(for feature: ScriptFeature) -> String {
        if !feature.isSaved {
            return "Save"
        } else {
            return feature.isEnabled ? "Disable" : "Enable"
        }
    }
    
    // กำหนดสีพื้นหลังปุ่มตามสถานะ
    func buttonBackgroundColor(for feature: ScriptFeature) -> Color {
        if !feature.isSaved {
            return Color.orange
        } else {
            return feature.isEnabled ? Color.red : Color.accentColor
        }
    }
    
    // จัดการการกดปุ่ม (บันทึก -> เปิดใช้งาน -> ปิดใช้งาน)
    func handleButtonAction(for feature: inout ScriptFeature) {
        if !feature.isSaved {
            // ยังไม่บันทึก ให้เช็คว่ากรอกครบทั้ง 2 ค่ารึยัง
            if !feature.originalValue.isEmpty && !feature.modifiedValue.isEmpty {
                feature.isSaved = true
                saveToJson()
            }
        } else {
            // บันทึกแล้ว สลับสถานะ Enable / Disable
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
    
    // MARK: - จัดการ JSON ใน Application Support
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
            let data = try JSONEncoder().encode(features)
            try data.write(to: url)
        } catch {
            print("Failed to save JSON: \(error)")
        }
    }
    
    func loadFromJson() {
        let url = getJSONFileURL()
        guard let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([ScriptFeature].self, from: data) else { return }
        features = decoded
    }
    
    func deleteItems(at offsets: IndexSet) {
        features.remove(atOffsets: offsets)
        saveToJson()
    }
}
