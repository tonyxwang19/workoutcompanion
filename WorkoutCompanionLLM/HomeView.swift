//
//  HomeView.swift
//  RunningCompanionLLM
//
//  Created by 王希宁的Macbook on 8/10/25.
//
import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 标题区域
                VStack(spacing: 10) {
                    Image(systemName: "figure.run.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("跑步伴侣")
                        .font(.largeTitle.bold())
                        .foregroundColor(.primary)
                    
                    Text("记录每一步的精彩")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                Spacer()
                
                // 功能卡片
                VStack(spacing: 16) {
                    FeatureCard(
                        icon: "map.circle.fill",
                        title: "实时轨迹",
                        description: "GPS精准定位，记录完整跑步路线"
                    )
                    
                    FeatureCard(
                        icon: "chart.bar.circle.fill",
                        title: "数据分析",
                        description: "距离、配速、时间，全面掌握运动数据"
                    )
                    
                    FeatureCard(
                        icon: "trophy.circle.fill",
                        title: "成就系统",
                        description: "解锁跑步成就，激励持续运动"
                    )
                }
                .padding(.horizontal)
                
                Spacer()
                
                // 开始跑步提示
                VStack(spacing: 8) {
                    Text("点击下方'跑步‘标签开始运动")
                        .font(.callout)
                        .foregroundColor(.secondary)
                    
                    Image(systemName: "arrow.down")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .padding(.bottom, 30)
            }
            .navigationTitle("首页")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}
