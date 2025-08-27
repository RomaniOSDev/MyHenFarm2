//
//  StatisticOfHenhousesView.swift
//  MyHenFarm2
//
//  Created by Роман Главацкий on 22.08.2025.
//

import SwiftUI
import Charts

struct StatisticOfHenhousesView: View {
    @StateObject private var viewModel = StatisticOfHenhousesViewModel()
    
    var body: some View {
        ZStack {
            Color.mainColorApp.ignoresSafeArea()
            VStack(spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Henhouse Statistics")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Chart of henhouse additions by date")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                
                // Main statistics
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    StatCard(title: "Total Henhouses", value: "\(viewModel.totalCoops)", color: .blue)
                    StatCard(title: "This Month", value: "\(viewModel.coopsThisMonth)", color: .green)
                    StatCard(title: "This Week", value: "\(viewModel.coopsThisWeek)", color: .orange)
                }
                .padding(.horizontal)
                
                // Chart
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Addition Dynamics")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Picker("Period", selection: $viewModel.selectedPeriod) {
                            ForEach(ChartPeriod.allCases, id: \.self) { period in
                                Text(period.rawValue).tag(period)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 200)
                    }
                    .padding(.horizontal)
                    
                    Chart {
                        ForEach(viewModel.chartData, id: \.date) { dataPoint in
                            LineMark(
                                x: .value("Date", dataPoint.date),
                                y: .value("Count", dataPoint.count)
                            )
                            .foregroundStyle(.blue)
                            .lineStyle(StrokeStyle(lineWidth: 3))
                            
                            AreaMark(
                                x: .value("Date", dataPoint.date),
                                y: .value("Count", dataPoint.count)
                            )
                            .foregroundStyle(.blue.opacity(0.1))
                            
                            PointMark(
                                x: .value("Date", dataPoint.date),
                                y: .value("Count", dataPoint.count)
                            )
                            .foregroundStyle(.blue)
                            .symbolSize(100)
                        }
                    }
                    .frame(height: 250)
                    .padding(.horizontal)
                    .chartXAxis {
                        AxisMarks(values: .stride(by: viewModel.selectedPeriod == .week ? .day : .weekOfYear)) { value in
                            if let date = value.as(Date.self) {
                                if viewModel.selectedPeriod == .week {
                                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                                } else {
                                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                                }
                            }
                        }
                    }
                    .chartYAxis {
                        AxisMarks { value in
                            AxisValueLabel()
                        }
                    }
                }
                
                // Monthly statistics
                VStack(alignment: .leading, spacing: 12) {
                    Text("Monthly Statistics")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .padding(.horizontal)
                    
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(viewModel.monthlyData, id: \.month) { monthData in
                                HStack {
                                    Text(monthData.month)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Text("\(monthData.count)")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.blue)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.gray.opacity(0.1))
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                Spacer()
            }
            .onAppear {
                viewModel.loadData()
            }
            .onChange(of: viewModel.selectedPeriod) { _ in
                viewModel.loadData()
            }
        }
    }
}

// MARK: - StatCard
struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
        )
    }
}

// MARK: - Chart Data Models
struct ChartDataPoint {
    let date: Date
    let count: Int
}

struct MonthlyData {
    let month: String
    let count: Int
}

enum ChartPeriod: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case quarter = "Quarter"
    
    var days: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .quarter: return 90
        }
    }
}

// MARK: - ViewModel
class StatisticOfHenhousesViewModel: ObservableObject {
    private let manager = CoreDataManager.instance
    
    @Published var totalCoops: Int = 0
    @Published var coopsThisMonth: Int = 0
    @Published var coopsThisWeek: Int = 0
    @Published var chartData: [ChartDataPoint] = []
    @Published var monthlyData: [MonthlyData] = []
    @Published var selectedPeriod: ChartPeriod = .month
    
    func loadData() {
        let coops = manager.getCoops()
        totalCoops = coops.count
        
        let calendar = Calendar.current
        let now = Date()
        
        // Henhouses this month
        coopsThisMonth = coops.filter { coop in
            guard let bildday = coop.bildday else { return false }
            return calendar.isDate(bildday, equalTo: now, toGranularity: .month)
        }.count
        
        // Henhouses this week
        coopsThisWeek = coops.filter { coop in
            guard let bildday = coop.bildday else { return false }
            return calendar.isDate(bildday, equalTo: now, toGranularity: .weekOfYear)
        }.count
        
        // Chart data based on selected period
        generateChartData(from: coops)
        
        // Monthly data
        generateMonthlyData(from: coops)
    }
    
    private func generateChartData(from coops: [Coop]) {
        let calendar = Calendar.current
        let now = Date()
        var dailyCounts: [Date: Int] = [:]
        
        // Initialize all days for the selected period
        for dayOffset in 0..<selectedPeriod.days {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) {
                let startOfDay = calendar.startOfDay(for: date)
                dailyCounts[startOfDay] = 0
            }
        }
        
        // Count henhouses by day
        for coop in coops {
            if let bildday = coop.bildday {
                let startOfDay = calendar.startOfDay(for: bildday)
                if dailyCounts[startOfDay] != nil {
                    dailyCounts[startOfDay, default: 0] += 1
                }
            }
        }
        
        // Sort by date and create array for chart
        chartData = dailyCounts
            .sorted { $0.key < $1.key }
            .map { ChartDataPoint(date: $0.key, count: $0.value) }
    }
    
    private func generateMonthlyData(from coops: [Coop]) {
        _ = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM yyyy"
        
        var monthlyCounts: [String: Int] = [:]
        
        for coop in coops {
            if let bildday = coop.bildday {
                let monthKey = dateFormatter.string(from: bildday)
                monthlyCounts[monthKey, default: 0] += 1
            }
        }
        
        monthlyData = monthlyCounts
            .sorted { $0.key < $1.key }
            .map { MonthlyData(month: $0.key, count: $0.value) }
    }
}

#Preview {
    StatisticOfHenhousesView()
}
