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
