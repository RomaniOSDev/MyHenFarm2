//
//  HendosesViewModel.swift
//  MyHenFarm2
//
//  Created by Роман Главацкий on 22.08.2025.
//

import Foundation

final class HendosesViewModel: ObservableObject {
    let manager = CoreDataManager.instance
    
    @Published var hendoses: [Coop] = []
    
    init(){
        getHendoses()
    }
    
    private func getHendoses() {
        hendoses = manager.getCoops()
    }
    
    private func saveHendoses() {
        hendoses.removeAll()
        manager.save()
        getHendoses()
    }
}
