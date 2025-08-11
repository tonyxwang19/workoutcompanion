//
//  SettingView.swift
//  WorkoutCompanionLLM
//
//  Created by 王希宁的Macbook on 8/11/25.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("userName") private var userName = ""
    @AppStorage("unitPreference") private var unitPreference = "metric"
    @AppStorage("darkMode") private var darkMode = false
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("用户信息")) {
                    TextField("请输入用户名", text: $userName)
                }
                
                Section(header: Text("偏好设置")) {
                    Picker("单位", selection: $unitPreference) {
                        Text("公制 (km)").tag("metric")
                        Text("英制 (mile)").tag("imperial")
                    }
                    .pickerStyle(.segmented)
                    
                    Toggle("深色模式", isOn: $darkMode)
                    Toggle("允许通知", isOn: $notificationsEnabled)
                }
                
                Section(header: Text("关于")) {
                    HStack {
                        Text("版本号")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("设置")
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}


