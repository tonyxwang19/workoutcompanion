import SwiftUI

struct Workout: Identifiable, Codable {
    let id = UUID()
    let type: WorkoutType
    let distance: Double // in meters
    let duration: TimeInterval // in seconds
    let startTime: Date
    let endTime: Date
    let calories: Int
    
    var formattedDistance: String {
        String(format: "%.2f km", distance / 1000)
    }
    
    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    var averagePace: String {
        guard distance > 0 else { return "--'--\"" }
        let pace = duration / 60 / (distance / 1000)
        let minutes = Int(pace)
        let seconds = Int((pace - Double(minutes)) * 60)
        return String(format: "%d'%02d\"", minutes, seconds)
    }
    
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: startTime)
    }
}

class WorkoutStore: ObservableObject {
    @Published var workouts: [Workout] = []
    
    private let saveKey = "saved_workouts"
    
    init() {
        loadWorkouts()
    }
    
    func addWorkout(_ workout: Workout) {
        workouts.insert(workout, at: 0)
        saveWorkouts()
    }
    
    func deleteWorkout(at offsets: IndexSet) {
        workouts.remove(atOffsets: offsets)
        saveWorkouts()
    }
    
    private func saveWorkouts() {
        if let encoded = try? JSONEncoder().encode(workouts) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    private func loadWorkouts() {
        if let data = UserDefaults.standard.data(forKey: saveKey) {
            if let decoded = try? JSONDecoder().decode([Workout].self, from: data) {
                workouts = decoded
            }
        }
    }
    
    func totalDistance() -> Double {
        workouts.reduce(0) { $0 + $1.distance }
    }
    
    func totalDuration() -> TimeInterval {
        workouts.reduce(0) { $0 + $1.duration }
    }
    
    func totalWorkouts() -> Int {
        workouts.count
    }
}

struct WorkoutRecordView: View {
    @StateObject private var store = WorkoutStore()
    @State private var showingAddWorkout = false
    
    var body: some View {
        NavigationView {
            VStack {
                if store.workouts.isEmpty {
                    emptyStateView
                } else {
                    summaryView
                    workoutList
                }
            }
            .navigationTitle("运动记录")
            .toolbar {
                Button(action: { showingAddWorkout = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
            }
            .sheet(isPresented: $showingAddWorkout) {
                AddWorkoutView(store: store)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.run")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text("暂无运动记录")
                .font(.title2)
                .foregroundColor(.gray)
            Text("点击右上角 + 开始记录你的第一次运动吧")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
    
    private var summaryView: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                SummaryCard(
                    title: "总距离",
                    value: String(format: "%.1f km", store.totalDistance() / 1000),
                    icon: "flame"
                )
                SummaryCard(
                    title: "总时长",
                    value: formatDuration(store.totalDuration()),
                    icon: "clock"
                )
                SummaryCard(
                    title: "总次数",
                    value: "\(store.totalWorkouts())",
                    icon: "trophy"
                )
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
    
    private var workoutList: some View {
        List {
            ForEach(store.workouts) { workout in
                WorkoutRow(workout: workout)
            }
            .onDelete(perform: store.deleteWorkout)
        }
        .listStyle(.plain)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            Text(value)
                .font(.headline)
                .foregroundColor(.primary)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct WorkoutRow: View {
    let workout: Workout
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: workout.type.icon)
                    .foregroundColor(.blue)
                Text(workout.type.rawValue)
                    .font(.headline)
                Spacer()
                Text(workout.formattedDistance)
                    .font(.title3.bold())
            }
            
            HStack {
                Text(workout.dateString)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(workout.formattedDuration)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("平均配速")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(workout.averagePace)
                    .font(.caption.bold())
                Spacer()
                Text("\(workout.calories) 卡路里")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

struct AddWorkoutView: View {
    @ObservedObject var store: WorkoutStore
    @Environment(\.dismiss) var dismiss
    
    @State private var workoutType: WorkoutType = .running
    @State private var distance: String = ""
    @State private var duration: String = ""
    @State private var calories: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("运动类型")) {
                    Picker("运动类型", selection: $workoutType) {
                        ForEach(WorkoutType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.icon).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Text("运动数据")) {
                    TextField("距离 (公里)", text: $distance)
                        .keyboardType(.decimalPad)
                    TextField("时长 (分钟)", text: $duration)
                        .keyboardType(.numberPad)
                    TextField("卡路里", text: $calories)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("添加运动记录")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveWorkout()
                    }
                    .disabled(!isValidInput)
                }
            }
        }
    }
    
    private var isValidInput: Bool {
        guard let dist = Double(distance),
              let dur = Double(duration),
              let cal = Int(calories) else {
            return false
        }
        return dist > 0 && dur > 0 && cal > 0
    }
    
    private func saveWorkout() {
        guard let dist = Double(distance),
              let dur = Double(duration),
              let cal = Int(calories) else {
            return
        }
        
        let now = Date()
        let workout = Workout(
            type: workoutType,
            distance: dist * 1000, // Convert km to meters
            duration: dur * 60,    // Convert minutes to seconds
            startTime: now.addingTimeInterval(-dur * 60),
            endTime: now,
            calories: cal
        )
        
        store.addWorkout(workout)
        dismiss()
    }
}

struct WorkoutRecordView_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutRecordView()
    }
}