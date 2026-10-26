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
    var isEnabled: Bool = false
    
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

// SwiftUI Implementation
struct ScriptManagerView: View {
    @State private var features: [ScriptFeature] = []
    @State private var showingAddAlert = false
    @State private var newName = ""
    
    var body: some View {
        NavigationView {
            List {
                ForEach($features) { $feature in
                    Section(header: Text(feature.name).font(.headline)) {
                        // ช่องกรอก Original Value
                        HStack {
                            Text("Original (I32):")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            TextField("e.g. 909000004", text: $feature.originalValue)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 170)
                                .onChange(of: feature.originalValue) { _ in saveToJson() }
                        }
                        
                        // ช่องกรอก Modified Value
                        HStack {
                            Text("Modified (I32):")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            TextField("e.g. 909040010", text: $feature.modifiedValue)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 170)
                                .onChange(of: feature.modifiedValue) { _ in saveToJson() }
                        }
                        
                        // สวิตช์เปิด/ปิดการทำงาน (สั่งรัน VMTool จริงทันที)
                        Toggle("Active Status", isOn: $feature.isEnabled)
                            .onChange(of: feature.isEnabled) { isOn in
                                triggerVMTool(for: feature, isOn: isOn)
                            }
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .listStyle(InsetGroupedListStyle())
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
    
    // MARK: - ทำงานจริงผ่าน VMTool สไตล์ H5GG
    func triggerVMTool(for feature: ScriptFeature, isOn: Bool) {
        let origVal = feature.originalValue
        let modVal = feature.modifiedValue
        
        if origVal.isEmpty || modVal.isEmpty { return }
        
        let valueType = VMMemValueType(rawValue: VMMemValueType.RawValue(VMMemValueTypeSignedInt.rawValue))
        let comparison = VMMemComparisonEQ
        
        if isOn {
            print("[\(feature.name)] OPEN: Search \(origVal) (I32) -> Edit to \(modVal) (I32)")
            VMTool.share().searchValue(origVal, type: valueType, comparison: comparison) { count, array in
                if count > 0 {
                    for model in array {
                        if let memModel = model as? MemModel {
                            memModel.value = modVal
                            memModel.type = valueType
                            VMTool.share().modifyValue(modVal, address: memModel.address, type: valueType)
                        }
                    }
                }
                VMTool.share().reset()
            }
        } else {
            print("[\(feature.name)] CLOSE: Search \(modVal) (I32) -> Revert to \(origVal) (I32)")
            VMTool.share().searchValue(modVal, type: valueType, comparison: comparison) { count, array in
                if count > 0 {
                    for model in array {
                        if let memModel = model as? MemModel {
                            memModel.value = origVal
                            memModel.type = valueType
                            VMTool.share().modifyValue(origVal, address: memModel.address, type: valueType)
                        }
                    }
                }
                VMTool.share().reset()
            }
        }
    }
    
    // MARK: - จัดการ JSON ใน Application Support (บันทึกชื่อและค่า โดยไม่บันทึกสถานะสวิตช์)
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
