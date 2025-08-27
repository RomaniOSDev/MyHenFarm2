//
//  HomeViewModel.swift
//  MyHenFarm2
//
//  Created by Роман Главацкий on 25.08.2025.
//

import Foundation
import SwiftUI
import Combine

enum FeedingType: CaseIterable {
    case vitamins
    case water
    case wetMash
    case grain
    
    var title: String {
        switch self {
        case .vitamins:
            return "Vitamins"
        case .water:
            return "Water"
        case .wetMash:
            return "Wet Mash"
        case .grain:
            return "Grain"
        }
    }
    
    var color: Color {
        switch self {
        case .vitamins:
            return .purple
        case .water:
            return .blue.opacity(0.7)
        case .wetMash:
            return .greenApp
        case .grain:
            return .yellow
        }
    }
}

final class HomeViewModel: ObservableObject {
    @Published var feedings: [Feeding] = []
    @Published var coopList: [Coop] = []
    @Published var eggLogs: [EggsLog] = []
    
    @Published var simpleTime: Date = Date()
    @Published var simpleType: FeedingType = .vitamins
    @Published var simpleCoop: Coop? = nil
    @Published var simpleNote: String = ""
    
    @Published var sortingCopp: Coop? = nil {
        didSet {
            print("🔄 sortingCopp changed to: \(sortingCopp?.name ?? "nil")")
        }
    }
    @Published var sortedEggsLog: [EggsLog] = [] {
        didSet {
            print("📊 sortedEggsLog updated: \(sortedEggsLog.count) items")
        }
    }
    
    @Published var isPresentAddLog: Bool = false
    @Published var simpleDateLog: Date = Date()
    @Published var simpleCountLog: String = ""
    @Published var simpleCoopLog: Coop? = nil
    @Published var simpleNoteLog: String = ""
    
    private var cancellables: Set<AnyCancellable> = []
    
    let manager = CoreDataManager.instance
    
   
    
    init(){
        getFeedings()
        getLogsEggs()
        // Отложим установку pipeline до загрузки данных
        Task { @MainActor in
            setupSorting()
        }
    }
    
    private func setupSorting() {
        print("🔍 Setting up sorting pipeline")
        $sortingCopp
            .combineLatest($eggLogs)
            .map { sortingCoop, eggLogs -> [EggsLog] in
                print("🔄 Sorting triggered - Coop: \(sortingCoop?.name ?? "nil"), Total logs: \(eggLogs.count)")
                
                guard let sortingCoop = sortingCoop else {
                    print("📋 No coop selected, showing all logs")
                    return eggLogs.sorted { $0.date ?? Date() > $1.date ?? Date() }
                }
                
                let filteredLogs = eggLogs.filter { $0.coop == sortingCoop }
                print("🎯 Filtered logs for coop '\(sortingCoop.name ?? "unknown")': \(filteredLogs.count)")
                
                return filteredLogs.sorted { $0.date ?? Date() > $1.date ?? Date() }
            }
            .assign(to: \.sortedEggsLog, on: self)
            .store(in: &cancellables)
    }
    
    func clearLogsSimpleData() {
        simpleCoopLog = nil
        simpleDateLog = Date()
        simpleCountLog = ""
        simpleNoteLog = ""
    }
    
    func deleteEggLog(_ eggLog: EggsLog) {
        manager.deleteEggsLog(eggLog)
        getLogsEggs()
    }
    func addLogEgg() {
        let newLogEggs = EggsLog(context: manager.context)
        newLogEggs.date = simpleDateLog
        newLogEggs.countEggs = Int16(simpleCountLog) ?? 0
        newLogEggs.coop = simpleCoopLog
        newLogEggs.note = simpleNoteLog
        saveLogEgg()
        print("new log: \(newLogEggs)")
        
    }
    
    func getLogsEggs() {
        eggLogs = manager.getEggsLogs()
        print("📥 Loaded \(eggLogs.count) egg logs from Core Data")
    }
    func saveLogEgg() {
        eggLogs.removeAll()
        manager.save()
        getLogsEggs()
        print("save log")
    }
    
    func deleteFeeding(_ feeding: Feeding) {
        manager.deleteFeeding(feeding)
        getFeedings()
    }
    
    func addFeeding() {
        let newFeeding = Feeding(context: manager.context)
        newFeeding.time = simpleTime
        newFeeding.type = simpleType.title
        newFeeding.coop = simpleCoop
        newFeeding.note = simpleNote
        saveFeeding()
    }
    
    func clearSimpleData() {
        self.simpleTime = Date()
        self.simpleType = .vitamins
        self.simpleCoop = nil
        self.simpleNote = ""
    }
    
    
     func getFeedings() {
        feedings = manager.getFeedings()
        coopList = manager.getCoops()
    }
    
    private func saveFeeding() {
        feedings.removeAll()
        manager.save()
        getFeedings()
    }
}
