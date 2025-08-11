import CoreLocation
import SwiftUI
import Combine
import MapKit

struct RunningMapView: UIViewRepresentable {
    @Binding var locations: [CLLocation]
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        guard locations.count > 1 else { return }
        
        let coordinates = locations.map { wgs84ToGcj02($0.coordinate) }
        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
        uiView.addOverlay(polyline)
        
        // 让地图显示全程轨迹
        let rect = polyline.boundingMapRect
        // 固定显示200米×200米区域
        let minWidth: Double = 1200
        let minHeight: Double = 1200

        // 计算中心点
        let center = MKMapPoint(x: rect.midX, y: rect.midY)

        // 计算最终显示的区域大小（轨迹范围和最小范围取较大值）
        let width = max(rect.size.width, minWidth)
        let height = max(rect.size.height, minHeight)

        // 生成新的区域，保证中心不变
        let finalRect = MKMapRect(
            origin: MKMapPoint(x: center.x - width / 2, y: center.y - height / 2),
            size: MKMapSize(width: width, height: height)
        )
        uiView.setVisibleMapRect(finalRect, edgePadding: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20), animated: true)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: RunningMapView
        
        init(_ parent: RunningMapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .systemBlue
                renderer.lineWidth = 5
                return renderer
            }
            return MKOverlayRenderer()
        }
    }
}

enum WorkoutType: String, CaseIterable {
    case running = "跑步"
    case cycling = "骑行"
    
    var icon: String {
        switch self {
        case .running: return "figure.run"
        case .cycling: return "figure.outdoor.cycle"
        }
    }
    
    var activityType: CLActivityType {
        switch self {
        case .running: return .fitness
        case .cycling: return .automotiveNavigation // 骑行使用导航模式更适合
        }
    }
    
    var distanceUnit: String {
        switch self {
        case .running: return "km"
        case .cycling: return "km"
        }
    }
    
    var speedUnit: String {
        switch self {
        case .running: return "min/km"
        case .cycling: return "km/h"
        }
    }
}

enum SheetState: Int {
    case collapsed
    case half
    case expanded
}

struct RunTrackingView: View {
    @StateObject var tracker = LocationTracker()
    @State private var startTime: Date?
    @State private var elapsed: TimeInterval = 0
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common)
    @State private var cancellable: Cancellable?
    @Binding var workoutType: WorkoutType
    @Binding var isRunning: Bool
    
    // Bottom Sheet 相关
    @State private var offsetY: CGFloat = 0
    @State private var isExpanded = false
    
    var body: some View {
        VStack {
            if !tracker.isLocationAvailable {
                VStack {
                    Image(systemName: "location.slash")
                        .font(.largeTitle)
                        .foregroundColor(.red)
                    Text("需要位置权限才能记录\(workoutType.rawValue)")
                        .font(.headline)
                    Button("请求权限") {
                        tracker.requestPermission()
                    }
                }
                .padding()
            } else {
                ZStack {
                    RunningMapView(locations: $tracker.locations)
                        .ignoresSafeArea()
                    
                    VStack {
                        Spacer()
                        
                        // Bottom Sheet
                        VStack {
                            Capsule()
                                .frame(width: 40, height: 5)
                                .foregroundColor(.gray.opacity(0.6))
                                .padding(.top, 8)
                            
                            // 基础数据
                            HStack(spacing: 40) {
                                VStack {
                                    Text("距离")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(totalDistance(from: tracker.locations) / 1000, specifier: "%.2f") \(workoutType.distanceUnit)")
                                        .font(.title2.bold())
                                }
                                VStack {
                                    Text("时间")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(formattedTime(elapsed))
                                        .font(.title2.bold())
                                }
                                VStack {
                                    Text(workoutType == .running ? "配速" : "速度")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(displaySpeed(from: tracker.locations, workoutType: workoutType))
                                        .font(.title2.bold())
                                        .font(.title2.bold())
                                }
                            }
                            .padding()
                            
                            // 展开后才显示的详细数据
                            if isExpanded {
                                Divider()
                                VStack(spacing: 16) {
                                    statItem(title: "累计爬升", value: totalAscent(from: tracker.locations), unit: "m")
                                    statItem(title: "累计下降", value: totalDescent(from: tracker.locations), unit: "m")
                                    statItem(title: "平均速度", value: averageSpeed(from: tracker.locations), unit: "m")
                                }
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                                .padding(.bottom, 20)
                            }
                            
                            Button(action: {
                                isRunning.toggle()
                            }) {
                                HStack {
                                    Image(systemName: "stop.circle.fill")
                                    Text("停止\(workoutType.rawValue)")
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 32)
                                .padding(.vertical, 12)
                                .background(Color.red)
                                .cornerRadius(25)
                            }
                            .padding(.bottom, 20)
                            
                        }
                        .frame(maxWidth: .infinity)
                        .background(.regularMaterial)
                        .cornerRadius(25)
                        .offset(y: offsetY)
                        .animation(.spring(), value: isExpanded)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let dragAmount = value.translation.height
                                    offsetY = dragAmount
                                }
                                .onEnded { value in
                                    withAnimation(.spring()) {
                                        if value.translation.height < -15 {
                                            isExpanded = true
                                        } else if value.translation.height > 15 {
                                            isExpanded = false
                                        }
                                        offsetY = 0
                                    }
                                }
                        )
                    }
                }
                .onAppear {
                    tracker.startTracking(activityType: workoutType.activityType)
                    startTime = Date()
                    timer = Timer.publish(every: 1, on: .main, in: .common)
                    cancellable = timer.connect()
                }
                .onReceive(timer) { _ in
                    if isRunning {
                        elapsed = Date().timeIntervalSince(startTime ?? Date())
                    }
                }
                .onDisappear {
                    cancellable?.cancel()
                    tracker.stopTracking()
                }
            }
        }
    }
    
    // 封装显示项
    func statItem(title: String, value: Double, unit: String = "") -> some View {
        VStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text("\(value, specifier: "%.2f")\(unit)")
                .font(.title2.bold())
        }
    }
}




func formattedTime(_ timeInterval: TimeInterval) -> String {
    let hours = Int(timeInterval) / 3600
    let minutes = Int(timeInterval) / 60 % 60
    let seconds = Int(timeInterval) % 60
    return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
}

func totalAscent(from locations: [CLLocation]) -> Double {
    var ascent = 0.0
    for i in 1..<locations.count {
        let diff = locations[i].altitude - locations[i-1].altitude
        if diff > 0 { ascent += diff }
    }
    return ascent
}

func totalDescent(from locations: [CLLocation]) -> Double {
    var descent = 0.0
    for i in 1..<locations.count {
        let diff = locations[i].altitude - locations[i-1].altitude
        if diff < 0 { descent += abs(diff) }
    }
    return descent
}

func averageSpeed(from locations: [CLLocation]) -> Double {
    guard locations.count > 1 else { return 0 }
    let distance = totalDistance(from: locations) / 1000 // km
    let time = locations.last!.timestamp.timeIntervalSince(locations.first!.timestamp) / 3600 // hours
    return time > 0 ? distance / time : 0
}

func maxSpeed(from locations: [CLLocation]) -> Double {
    guard !locations.isEmpty else { return 0 }
    return locations.map { max($0.speed, 0) * 3.6 }.max() ?? 0 // m/s 转 km/h
}

func pace(from distance: Double, duration: TimeInterval) -> String {
    guard distance >= 10, duration >= 5 else { return "--'--\"" }
    let paceValue = duration / 60 / (distance / 1000) // min/km
    let minutes = Int(paceValue)
    let seconds = Int((paceValue - Double(minutes)) * 60)
    return String(format: "%d'%02d\"", minutes, seconds)
}

func displaySpeed(from locations: [CLLocation], workoutType: WorkoutType) -> String {
    guard let speedKmH = instantSpeed(from: locations) else {
        return workoutType == .running ? "--'--\"" : "--.-"
    }
    switch workoutType {
    case .running:
        let paceMinPerKm = 60 / speedKmH
        let minutes = Int(paceMinPerKm)
        let seconds = Int((paceMinPerKm - Double(minutes)) * 60)
        return String(format: "%d'%02d\"", minutes, seconds)
    case .cycling:
        return String(format: "%.1f", speedKmH)
    }
}

func instantSpeed(from locations: [CLLocation], windowSeconds: TimeInterval = 10) -> Double? {
    guard locations.count > 1 else { return nil }
    guard let latest = locations.last else { return nil }
    let cutoffTime = latest.timestamp.addingTimeInterval(-windowSeconds)
    
    // 找到距离当前时间windowSeconds秒内的起点
    guard let start = locations.first(where: { $0.timestamp >= cutoffTime }) else { return nil }
    
    let distance = latest.distance(from: start) // 米
    let duration = latest.timestamp.timeIntervalSince(start.timestamp) // 秒
    
    guard distance > 0 && duration > 0 else { return nil }
    
    return (distance / 1000) / (duration / 3600) // km/h
}




