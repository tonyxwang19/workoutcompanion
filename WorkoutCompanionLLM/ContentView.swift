//
//  ContentView.swift
//  runningdemo
//
//  Created by 王希宁的Macbook on 8/8/25.
//
import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("首页")
                }
            
            WorkoutGoalView()
                .tabItem {
                    Image(systemName: "figure.run")
                    Text("运动")
                }
            
            WorkoutRecordView()
                .tabItem {
                    Image(systemName: "list.bullet.rectangle")
                    Text("记录")
                }
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("设置")
                }
        }
    }
}

#Preview {
    ContentView()
}
