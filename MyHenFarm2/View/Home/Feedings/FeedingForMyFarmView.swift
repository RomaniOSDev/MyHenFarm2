//
//  FeedingForMyFarmView.swift
//  MyHenFarm2
//
//  Created by Роман Главацкий on 25.08.2025.
//

import SwiftUI

struct FeedingForMyFarmView: View {
    @StateObject var vm: HomeViewModel
    var body: some View {
        ZStack {
            Color.mainColorApp.ignoresSafeArea()
            VStack {
                NavigationLink {
                    AddFeedingForMyFarmView(vm: vm)
                } label: {
                    HStack {
                        Text("Add Feeding")
                        Image(systemName: "plus")
                    }
                }
                ScrollView {
                    ForEach(vm.feedings) { feeding in
                        CellForFeeding(feeding: feeding, deleteAction: {vm.deleteFeeding(feeding)})
                    }
                }

            }.padding()
        }
        .navigationTitle("Feeding")
    }
}

#Preview {
    FeedingForMyFarmView(vm: HomeViewModel())
}
