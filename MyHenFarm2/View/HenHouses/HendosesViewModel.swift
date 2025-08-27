//
//  HendosesViewModel.swift
//  MyHenFarm2
//
//  Created by Роман Главацкий on 22.08.2025.
//

import Foundation
import _PhotosUI_SwiftUI

final class HendosesViewModel: ObservableObject {
    let manager = CoreDataManager.instance
    
    @Published var hendoses: [Coop] = []
    @Published var chikens: [Chiken] = []
    @Published var simppleChikenList: [Chiken] = []
    
    @Published var isPresentedChikenLists: Bool = false
    
    @Published var selectedPhoto: PhotosPickerItem?
    @Published var simpleimage: UIImage? = nil
    @Published var simplename: String = ""
    @Published var simpleDate: Date = Date()
    
    init(){
        getHendoses()
        getChikens()
    }
    
    func getCountChiken() -> Int {
        var count: Int = 0
        for hendose in hendoses {
            if let chiken = hendose.chiken?.allObjects as? [Chiken] {
                count += chiken.count
            }
        }
        return count
    }
    
    func deleteHendHouse(at: Coop){
        manager.deleteCoop(at)
        getHendoses()
    }
    
    func addNewHendose() {
        let newHendose = Coop(context: manager.context)
        
        newHendose.name = simplename
        newHendose.bildday = simpleDate
        if let imageData = convertImageToData(simpleimage ?? UIImage()) {
            newHendose.photo = imageData
        }
        if !simppleChikenList.isEmpty {
            for chiken in simppleChikenList {
                chiken.coop = newHendose
            }
        }
        
        saveHendoses()
    }
    
    func clearSimpleData() {
        simpleimage = nil
        simplename = ""
        simpleDate = Date()
        simppleChikenList.removeAll()
    }
    
    func includeChikensForSimple(chiken: Chiken) -> Bool {
        if simppleChikenList.firstIndex(where: { $0.id == chiken.id }) != nil {
                return false
            } else {
                return true
            }
    }
    
    func addChikenToHendose(chiken: Chiken) {
        if simppleChikenList.contains(where: { $0.id == chiken.id }) {
            simppleChikenList.removeAll(where: { $0.id == chiken.id })
        }else{
            simppleChikenList.append(chiken)
        }
    }
    
    func removeChikenFromHendose(chiken: Chiken) {
        if let index = simppleChikenList.firstIndex(where: { $0.id == chiken.id }) {
            simppleChikenList.remove(at: index)
        }
    }
    
    private func saveHendHouse() {
        hendoses.removeAll()
        manager.save()
        getHendoses()
    }
    
    private func getChikens() {
        chikens = manager.getChikens()
    }
    private func getHendoses() {
        hendoses = manager.getCoops()
    }
    
    private func saveHendoses() {
        hendoses.removeAll()
        manager.save()
        getHendoses()
    }
    //MARK: - Converting data
        private func convertImageToData(_ image: UIImage) -> Data? {
            return image.jpegData(compressionQuality: 1.0)
        }
}
