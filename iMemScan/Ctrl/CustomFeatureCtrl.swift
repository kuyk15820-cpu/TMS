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
    
    enum CodingKeys: String, CodingKey {
        case name, originalValue, modifiedValue
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

// SwiftUI Implementation with Custom UI Design
struct ScriptManagerView: View {
    @State private var features: [ScriptFeature] = []
    @State private var showingAddAlert = false
    @State private var newName = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach($features) { $feature in
                        VStack(alignment: .leading, spacing: 12) {
                            // ชื่อฟีเจอร์
                            Text(feature.name)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            // แถวกรอก Input พร้อมเส้นคั่นกลาง
                            HStack(spacing: 0) {
                                // ช่อง Original
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("ORIGINAL")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.secondary)
                                    TextField("909000004", text: $feature.originalValue)
                                        .keyboardType(.numberPad)
                                        .font(.system(size: 14, design: .monospaced))
                                        .onChange(of: feature.originalValue) { _ in saveToJson() }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 8)
                                
                                // เส้นแบ่งคั่นกลาง
                                Divider()
                                    .frame(height: 35)
                                    .background(Color.secondary.opacity(0.3))
                                
                                // ช่อง Modified
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("MODIFIED")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.secondary)
                                    TextField("909040010", text: $feature.modifiedValue)
                                        .keyboardType(.numberPad)
                                        .font(.system(size: 14, design: .monospaced))
                                        .onChange(of: feature.modifiedValue) { _ in saveToJson() }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 8)
                            }
                            .padding(8)
                            .background(Color(.secondarySystemBackground).opacity(0.6))
                            .cornerRadius(8)
                            
                            // ปุ่มกดด้านล่าง (Apply / Revert)
                            HStack(spacing: 12) {
                                Button(action: {
                                    executeVMTool(original: feature.originalValue, modified: feature.modifiedValue, isApply: true)
                                }) {
                                    Text("Apply")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(Color.accentColor)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                                
                                Button(action: {
                                    executeVMTool(original: feature.originalValue, modified: feature.modifiedValue, isApply: false)
                                }) {
                                    Text("Revert")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(Color(.systemGray5))
                                        .foregroundColor(.primary)
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        // Table แบบโค้ง พร้อม Border สีเล็กน้อย
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                        )
                        .padding(.horizontal)
                    }
                    .onDelete(perform: deleteItems)
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
                        let newFeature = ScriptFeature(name: newName, originalValue: "", modifiedValue: "")
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
    
    // MARK: - ทำงานจริงผ่าน VMTool สไตล์ H5GG เมื่อกดปุ่ม
    func executeVMTool(original: String, modified: String, isApply: Bool) {
        if original.isEmpty || modified.isEmpty { return }
        
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
