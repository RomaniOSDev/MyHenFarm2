//
//  CoreDataManager.swift
//  MyHenFarm2
//
//  Created by Роман Главацкий on 21.08.2025.
//

import Foundation
import CoreData

final class CoreDataManager {
    static let instance = CoreDataManager()
    
    let container: NSPersistentContainer
    let context: NSManagedObjectContext
    
    init() {
        container = NSPersistentContainer(name: "Farm")
        container.loadPersistentStores { descption, error in
            if let error = error{
                print("Error looading core data\(error)")
            }
        }
        context = container.viewContext
    }
    
    func save() {
        do {
            try context.save()
        }catch let error {
            print("Save data erroe \(error.localizedDescription)")
        }
        
    }
    
    //MARK: - EggsLog
    func getEggsLogs() -> [EggsLog] {
        let fetchRequest: NSFetchRequest<EggsLog> = EggsLog.fetchRequest()
        do {
            return try context.fetch(fetchRequest)
        }catch let error {
            print("Fetch error \(error.localizedDescription)")
            return []
        }
    }
    
    func deleteEggsLog(_ eggsLog: EggsLog) {
        context.delete(eggsLog)
        save()
    }
    
    //MARK: - Feeding
    func getFeedings() -> [Feeding] {
        let fetchRequest: NSFetchRequest<Feeding> = Feeding.fetchRequest()
        do {
            return try context.fetch(fetchRequest)
        }catch let error {
            print("Fetch error \(error.localizedDescription)")
            return []
        }
    }
    
    func deleteFeeding(_ feeding: Feeding) {
        context.delete(feeding)
        save()
    }
    
    //MARK: - Coops
    func getCoops() -> [Coop] {
        let fetchRequest: NSFetchRequest<Coop> = Coop.fetchRequest()
        do {
            return try context.fetch(fetchRequest)
        }catch let error {
            print("Fetch error \(error.localizedDescription)")
            return []
        }
    }
    
    func deleteCoop(_ coop: Coop) {
        context.delete(coop)
        save()
    }
    
    //MARK: - Chiken
    func getChikens() -> [Chiken] {
        let fetchRequest: NSFetchRequest<Chiken> = Chiken.fetchRequest()
        do {
            return try context.fetch(fetchRequest)
        }catch let error {
            print("Fetch error \(error.localizedDescription)")
            return []
        }
    }
    func deleteChiken(_ chiken: Chiken) {
        context.delete(chiken)
        save()
    }
}
