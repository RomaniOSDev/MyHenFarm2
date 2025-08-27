//
//  AggsFeedingStatisticView.swift
//  MyHenFarm2
//
//  Created by Роман Главацкий on 25.08.2025.
//

import SwiftUI
import Charts

struct AggsFeedingStatisticView: View {
    @StateObject private var vm = HomeViewModel()
    @State private var selectedTimeRange: TimeRange = .week
    @State private var selectedCoop: Coop? = nil
    
    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
        
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .year: return 365
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.mainColorApp.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Заголовок и статистика
                        headerSection
                        
                        // Фильтры
                        filterSection
                        
                        // График
                        chartSection
                        
                        // Детальная статистика
                        detailedStatsSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Eggs Statistics")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            vm.getLogsEggs()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Eggs Collected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(totalEggsCollected)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("For \(selectedTimeRange.rawValue.lowercased())")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(eggsInTimeRange)")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.greenApp)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(16)
        }
    }
    
    // MARK: - Filter Section
    private var filterSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Filters")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            HStack(spacing: 12) {
                // Выбор периода
                Menu {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Button(range.rawValue) {
                            selectedTimeRange = range
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedTimeRange.rawValue)
                        Image(systemName: "chevron.down")
                    }
                    .foregroundColor(.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .cornerRadius(8)
                }
                
                // Выбор курятника
                Menu {
                    Button("All Coops") {
                        selectedCoop = nil
                    }
                    ForEach(vm.coopList) { coop in
                        Button(coop.name ?? "No Name") {
                            selectedCoop = coop
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedCoop?.name ?? "All Coops")
                        Image(systemName: "chevron.down")
                    }
                    .foregroundColor(.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .cornerRadius(8)
                }
            }
        }
    }
    
    // MARK: - Chart Section
    private var chartSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Egg Collection Chart")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            if chartData.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("No data to display")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(16)
            } else {
                Chart(chartData) { data in
                    LineMark(
                        x: .value("Дата", data.date),
                        y: .value("Яйца", data.eggCount)
                    )
                    .foregroundStyle(Color.blue)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    
                    AreaMark(
                        x: .value("Дата", data.date),
                        y: .value("Яйца", data.eggCount)
                    )
                    .foregroundStyle(Color.blue.opacity(0.1))
                    
                    PointMark(
                        x: .value("Дата", data.date),
                        y: .value("Яйца", data.eggCount)
                    )
                    .foregroundStyle(Color.blue)
                    .symbolSize(100)
                }
                .frame(height: 200)
                .padding()
                .background(Color.white)
                .cornerRadius(16)
            }
        }
    }
    
    // MARK: - Detailed Stats Section
    private var detailedStatsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Detailed Statistics")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                EggsStatCard(
                    title: "Average per Day",
                    value: "\(averageEggsPerDay)",
                    color: .greenApp
                )
                
                EggsStatCard(
                    title: "Max per Day",
                    value: "\(maxEggsInDay)",
                    color: .orange
                )
                
                EggsStatCard(
                    title: "Min per Day",
                    value: "\(minEggsInDay)",
                    color: .red
                )
                
                EggsStatCard(
                    title: "Collection Days",
                    value: "\(daysWithCollection)",
                    color: .blue
                )
            }
        }
    }
    
    // MARK: - Computed Properties
    private var filteredLogs: [EggsLog] {
        let logs = selectedCoop != nil ? 
            vm.eggLogs.filter { $0.coop == selectedCoop } : 
            vm.eggLogs
        
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -selectedTimeRange.days, to: Date()) ?? Date()
        
        return logs.filter { log in
            guard let date = log.date else { return false }
            return date >= cutoffDate
        }
    }
    
    private var totalEggsCollected: Int {
        vm.eggLogs.reduce(0) { $0 + Int($1.countEggs) }
    }
    
    private var eggsInTimeRange: Int {
        filteredLogs.reduce(0) { $0 + Int($1.countEggs) }
    }
    
    private var chartData: [EggsChartDataPoint] {
        let calendar = Calendar.current
        let groupedLogs = Dictionary(grouping: filteredLogs) { log in
            calendar.startOfDay(for: log.date ?? Date())
        }
        
        let sortedDates = groupedLogs.keys.sorted()
        
        return sortedDates.map { date in
            let totalEggs = groupedLogs[date]?.reduce(0) { $0 + Int($1.countEggs) } ?? 0
            return EggsChartDataPoint(date: date, eggCount: totalEggs)
        }
    }
    
    private var averageEggsPerDay: Int {
        let days = chartData.count
        return days > 0 ? eggsInTimeRange / days : 0
    }
    
    private var maxEggsInDay: Int {
        chartData.map { $0.eggCount }.max() ?? 0
    }
    
    private var minEggsInDay: Int {
        chartData.map { $0.eggCount }.min() ?? 0
    }
    
    private var daysWithCollection: Int {
        chartData.count
    }
}

// MARK: - Chart Data Model
struct EggsChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let eggCount: Int
}

// MARK: - Stat Card View
struct EggsStatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
}

#Preview {
    AggsFeedingStatisticView()
}
