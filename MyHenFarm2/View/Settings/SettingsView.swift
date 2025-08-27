//
//  Settings.swift
//  MyHenFarm2
//
//  Created by Роман Главацкий on 21.08.2025.
//

import SwiftUI
import StoreKit
import CoreData

struct SettingsView: View {
    @StateObject private var vm = HomeViewModel()
    @AppStorage("eggPrice") private var eggPrice: Double = 0.0
    @State private var showingResetAlert = false
    @State private var showingPolicy = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.mainColorApp.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Price Settings Section
                        priceSettingsSection
                        
                        // Income Statistics Section
                        incomeStatisticsSection
                        
                        // App Actions Section
                        appActionsSection
                        
                        // Data Management Section
                        dataManagementSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            vm.getLogsEggs()
        }
        .alert("Reset All Data", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetAllData()
            }
        } message: {
            Text("This action will permanently delete all your farm data including chickens, coops, feeding records, and egg logs. This action cannot be undone.")
        }
        .sheet(isPresented: $showingPolicy) {
            PolicyView()
        }
    }
    
    // MARK: - Price Settings Section
    private var priceSettingsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Price Settings")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            VStack(spacing: 12) {
                HStack {
                    Text("Price per Egg")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                }
                
                HStack {
                    Text("$")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    TextField("0.00", value: $eggPrice, format: .number)
                        .keyboardType(.decimalPad)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.trailing)
                    
                    Text("USD")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
            }
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(16)
        }
    }
    
    // MARK: - Income Statistics Section
    private var incomeStatisticsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Income Statistics")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                IncomeCard(
                    title: "Today",
                    amount: todayIncome,
                    color: .greenApp
                )
                
                IncomeCard(
                    title: "This Month",
                    amount: monthIncome,
                    color: .blue
                )
                
                IncomeCard(
                    title: "This Year",
                    amount: yearIncome,
                    color: .orange
                )
                
                IncomeCard(
                    title: "Total",
                    amount: totalIncome,
                    color: .purple
                )
            }
        }
    }
    
    // MARK: - App Actions Section
    private var appActionsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("App Actions")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            VStack(spacing: 12) {
                Button(action: {SKStoreReviewController.requestReview()}) {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("Rate App")
                            .fontWeight(.medium)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .foregroundColor(.primary)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                }
                
                Button(action: {
                   if let url = URL(string: "https://www.termsfeed.com/live/01379993-bcbb-40b2-972f-dbed3ca72b10") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(.blue)
                        Text("Privacy Policy")
                            .fontWeight(.medium)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .foregroundColor(.primary)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                }
            }
        }
    }
    
    // MARK: - Data Management Section
    private var dataManagementSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Data Management")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            Button(action: { showingResetAlert = true }) {
                HStack {
                    Image(systemName: "trash.fill")
                        .foregroundColor(.red)
                    Text("Reset All Data")
                        .fontWeight(.medium)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .foregroundColor(.primary)
                .padding()
                .background(Color.white)
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Computed Properties
    private var todayIncome: Double {
        let today = Calendar.current.startOfDay(for: Date())
        let todayLogs = vm.eggLogs.filter { log in
            guard let date = log.date else { return false }
            return Calendar.current.isDate(date, inSameDayAs: today)
        }
        let todayEggs = todayLogs.reduce(0) { $0 + Int($1.countEggs) }
        return Double(todayEggs) * eggPrice
    }
    
    private var monthIncome: Double {
        let calendar = Calendar.current
        let now = Date()
        let monthStart = calendar.dateInterval(of: .month, for: now)?.start ?? now
        
        let monthLogs = vm.eggLogs.filter { log in
            guard let date = log.date else { return false }
            return date >= monthStart
        }
        let monthEggs = monthLogs.reduce(0) { $0 + Int($1.countEggs) }
        return Double(monthEggs) * eggPrice
    }
    
    private var yearIncome: Double {
        let calendar = Calendar.current
        let now = Date()
        let yearStart = calendar.dateInterval(of: .year, for: now)?.start ?? now
        
        let yearLogs = vm.eggLogs.filter { log in
            guard let date = log.date else { return false }
            return date >= yearStart
        }
        let yearEggs = yearLogs.reduce(0) { $0 + Int($1.countEggs) }
        return Double(yearEggs) * eggPrice
    }
    
    private var totalIncome: Double {
        let totalEggs = vm.eggLogs.reduce(0) { $0 + Int($1.countEggs) }
        return Double(totalEggs) * eggPrice
    }
    
    // MARK: - Actions
    private func rateApp() {
        SKStoreReviewController.requestReview()
    }
    
    private func resetAllData() {
        // Reset all Core Data
        let manager = CoreDataManager.instance
        
        // Delete all entities
        let fetchRequestEggs: NSFetchRequest<NSFetchRequestResult> = EggsLog.fetchRequest()
        let deleteRequestEggs = NSBatchDeleteRequest(fetchRequest: fetchRequestEggs)
        
        let fetchRequestFeedings: NSFetchRequest<NSFetchRequestResult> = Feeding.fetchRequest()
        let deleteRequestFeedings = NSBatchDeleteRequest(fetchRequest: fetchRequestFeedings)
        
        let fetchRequestChickens: NSFetchRequest<NSFetchRequestResult> = Chiken.fetchRequest()
        let deleteRequestChickens = NSBatchDeleteRequest(fetchRequest: fetchRequestChickens)
        
        let fetchRequestCoops: NSFetchRequest<NSFetchRequestResult> = Coop.fetchRequest()
        let deleteRequestCoops = NSBatchDeleteRequest(fetchRequest: fetchRequestCoops)
        
        do {
            try manager.context.execute(deleteRequestEggs)
            try manager.context.execute(deleteRequestFeedings)
            try manager.context.execute(deleteRequestChickens)
            try manager.context.execute(deleteRequestCoops)
            try manager.context.save()
            
            // Reset price
            eggPrice = 0.0
            
            // Refresh data
            vm.getLogsEggs()
            
            print("✅ All data reset successfully")
        } catch {
            print("❌ Error resetting data: \(error)")
        }
    }
}

// MARK: - Income Card View
struct IncomeCard: View {
    let title: String
    let amount: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Text("$\(amount, specifier: "%.2f")")
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

// MARK: - Policy View
struct PolicyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Privacy Policy")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.top)
                    
                    Text("Last updated: \(Date().formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Group {
                        Text("Data Collection")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("This app collects and stores farm management data locally on your device, including information about chickens, coops, feeding schedules, and egg collection logs.")
                        
                        Text("Data Usage")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("All data is used solely for the purpose of managing your farm operations. No data is transmitted to external servers or shared with third parties.")
                        
                        Text("Data Storage")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("Your farm data is stored locally using Core Data. You can reset all data at any time through the Settings menu.")
                        
                        Text("Contact")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("If you have any questions about this privacy policy, please contact us through the app store.")
                    }
                    .font(.body)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
