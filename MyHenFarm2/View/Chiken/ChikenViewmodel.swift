//
//  ChikenViewmodel.swift
//  MyHenFarm2
//
//  Created by Роман Главацкий on 21.08.2025.
//

import Foundation
import UIKit
import _PhotosUI_SwiftUI

final class ChikenViewmodel: ObservableObject {
    let manager = CoreDataManager.instance
    
    @Published var chikens: [Chiken] = []
    @Published var selectedPhoto: PhotosPickerItem?
    
    @Published var simplename: String = ""
    @Published var simplebreed: String = ""
    @Published var simpleage: String = ""
    @Published var simpleimage: UIImage? = nil
    
    @Published var isPresenrAddView: Bool = false
    
    init(){
        getChikens()
    }
    
    //MARK: - Open method
    func deleteChiken(chiken: Chiken){
        manager.deleteChiken(chiken)
        getChikens()
    }
    func clearData(){
        simplename = ""
        simplebreed = ""
        simpleage = ""
        simpleimage = nil
    }
    
    func tapAdd(){
        addChiken()
        isPresenrAddView.toggle()
    }
    
    //MARK: - Private method
    private func getChikens() {
        chikens = manager.getChikens()
    }
    private func saveData(){
        chikens.removeAll()
        manager.save()
        getChikens()
    }
    
    
    private func addChiken(){
        let newChiken = Chiken(context: manager.context)
        newChiken.name = simplename
        newChiken.breed = simplebreed
        newChiken.age = Int16(simpleage) ?? 0
        if let imageData = convertImageToData(simpleimage ?? UIImage()) {
            newChiken.photo = imageData
        }
        saveData()
    }
    
    //MARK: - Converting data
        private func convertImageToData(_ image: UIImage) -> Data? {
            return image.jpegData(compressionQuality: 1.0)
        }
    
}
