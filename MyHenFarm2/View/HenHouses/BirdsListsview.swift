//
//  BirdsListsview.swift
//  MyHenFarm2
//
//  Created by Роман Главацкий on 24.08.2025.
//

import SwiftUI

struct BirdsListsview: View {
    @StateObject var vm: HendosesViewModel
    var body: some View {
        ZStack {
            Color.mainColorApp.edgesIgnoringSafeArea(.all)
            VStack {
                ScrollView {
                    if vm.chikens.isEmpty {
                        Text("No birds")
                    }else{
                        ForEach(vm.chikens) { hen in
                            Button {
                                vm.addChikenToHendose(chiken: hen)
                            } label: {
                                CellForChokenView(chiken: hen, action: {
                                    ()
                                })
                            }
                            .opacity(vm.includeChikensForSimple(chiken: hen) ? 1 : 0.3)

                        }
                    }
                }
            }.padding()
        }
    }
}

#Preview {
    BirdsListsview(vm: HendosesViewModel())
}
