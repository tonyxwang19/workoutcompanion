import SwiftUI

struct WorkoutGoalView: View {
    @State var workoutType: WorkoutType = .running
    @State var isRunning = false
    @State private var targetDistance: String = ""
    @State private var targetDuration: String = ""
    @State private var targetCalories: String = ""
    
    
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
        }
        .fullScreenCover(isPresented: $isRunning) {
            RunTrackingView(workoutType: $workoutType, isRunning: $isRunning)
        }
    }
}
