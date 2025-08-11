import SwiftUI

struct Interval: Identifiable, Equatable {
    let id = UUID()
    var name: String
    var distance: String? // 可选，公里或米
    var duration: String? // 可选，分钟或秒
    var repeats: Int = 1
}

struct IntervalEditView: View {
    @Binding var intervals: [Interval]
    @Environment(\.presentationMode) var presentationMode
    
    // 这里改成用合适类型存储数字，距离用Double，时间用Int，配速用Double
    @State private var distance: Double = 1.0     // 公里
    @State private var duration: Int = 10         // 分钟
    @State private var pace: Double = 5.0         // 分钟/公里
    @State private var repeats: Int = 1
    
    @State private var name: String = "自定义分段"
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(intervals) { interval in
                        VStack(alignment: .leading) {
                            Text(interval.name).font(.headline)
                            HStack {
                                if let distStr = interval.distance, let dist = Double(distStr) {
                                    Text(String(format: "距离: %.1f 公里", dist))
                                }
                                if let durStr = interval.duration, let dur = Int(durStr) {
                                    Text("时长: \(dur) 分钟")
                                }
                                Text("次数: \(interval.repeats)")
                            }
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        }
                    }
                    .onDelete { indices in
                        intervals.remove(atOffsets: indices)
                    }
                    .onMove { indices, newOffset in
                        intervals.move(fromOffsets: indices, toOffset: newOffset)
                    }
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("设置分段参数")
                        .font(.headline)
                    
                    // 名称自定义
                    TextField("分段名称", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    // 距离选择 0.1km 到 20km，步长0.1km
                    HStack {
                        Text("距离 (公里)")
                        Spacer()
                        Stepper(value: $distance, in: 0...20, step: 0.1) {
                            Text(String(format: "%.1f", distance))
                        }
                    }
                    
                    // 时间选择 0~120分钟
                    HStack {
                        Text("时长 (分钟)")
                        Spacer()
                        Stepper(value: $duration, in: 0...120) {
                            Text("\(duration)")
                        }
                    }
                    
                    // 配速（分钟/公里） 2~10 分钟/公里，步长0.1
                    HStack {
                        Text("配速 (分/公里)")
                        Spacer()
                        Stepper(value: $pace, in: 2...10, step: 0.1) {
                            Text(String(format: "%.1f", pace))
                        }
                    }
                    
                    // 次数
                    HStack {
                        Text("次数")
                        Spacer()
                        Stepper(value: $repeats, in: 1...20) {
                            Text("\(repeats)")
                        }
                    }
                    
                    Button("添加分段") {
                        let interval = Interval(name: name,
                                                distance: distance > 0 ? String(format: "%.1f", distance) : nil,
                                                duration: duration > 0 ? String(duration) : nil,
                                                repeats: repeats)
                        intervals.append(interval)
                        // 重置默认值
                        name = "自定义分段"
                        distance = 1.0
                        duration = 10
                        pace = 5.0
                        repeats = 1
                    }
                    .disabled(name.isEmpty)
                    .padding(.top)
                }
                .padding()
            }
            .navigationTitle("编辑运动分段")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct LLMGIntervalGenerateView: View {
    var body: some View {
        NavigationView {
            
        }
        .navigationTitle("智能生成分段计划")
    }
}


struct WorkoutGoalView: View {
    @State var workoutType: WorkoutType = .running
    @State var isRunning = false
    @State private var targetDistance: String = ""
    @State private var targetDuration: String = ""
    @State private var targetCalories: String = ""
    
    // 新增分段数组
    @State private var intervals: [Interval] = []
    @State private var showIntervalEditor = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("选择运动类型")
                        .font(.headline)
                    
                    Picker("运动类型", selection: $workoutType) {
                        ForEach(WorkoutType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.icon).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("设置目标")
                        .font(.headline)
                    
                    VStack(spacing: 20) {
                        HStack {
                            Image(systemName: "target")
                                .foregroundColor(.blue)
                            TextField("目标距离 (公里)", text: $targetDistance)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(.green)
                            TextField("目标时长 (分钟)", text: $targetDuration)
                                .keyboardType(.numberPad)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        HStack {
                            Image(systemName: "flame")
                                .foregroundColor(.orange)
                            TextField("目标卡路里", text: $targetCalories)
                                .keyboardType(.numberPad)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                }
                .padding(.horizontal)
                
                // 新增分段编辑入口
                VStack(alignment: .leading, spacing: 8) {
                    Text("运动分段计划")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if intervals.isEmpty {
                        Text("未设置分段计划")
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(intervals) { interval in
                                    VStack {
                                        Text(interval.name)
                                            .font(.caption)
                                        if let dist = interval.distance {
                                            Text("\(dist) km")
                                                .font(.caption2)
                                        } else if let dur = interval.duration {
                                            Text("\(dur) min")
                                                .font(.caption2)
                                        }
                                        Text("×\(interval.repeats)")
                                            .font(.caption2)
                                    }
                                    .padding(8)
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(8)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    Button("编辑分段计划") {
                        showIntervalEditor = true
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                Button(action: {
                    isRunning = true
                }) {
                    HStack {
                        Image(systemName: "play.circle.fill")
                        Text("开始运动")
                    }
                    .font(.title3.bold())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.green)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .navigationTitle("运动目标")
            .fullScreenCover(isPresented: $isRunning) {
                RunTrackingView(workoutType: $workoutType, isRunning: $isRunning)
            }
            .sheet(isPresented: $showIntervalEditor) {
                IntervalEditView(intervals: $intervals)
            }
        }
    }
}


#Preview {
    WorkoutGoalView()
}
