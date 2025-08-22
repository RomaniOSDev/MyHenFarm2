//
//  HenhousesView.swift
//  MyHenFarm2
//
//  Created by Роман Главацкий on 21.08.2025.
//

import SwiftUI

struct HenhousesView: View {
    @StateObject var vm = HendosesViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.mainColorApp.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        HStack {
                            VStack(alignment: .leading){
                                Image(.coop)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 150, height: 100)
                                
                                Text("\(vm.hendoses.count) Coops")
                                Text("0 Chikens")
                            }
                            .frame(width: 150, height: 160)
                            .padding()
                            .background(Color.white.cornerRadius(20))
                            
                            StatisticOfHenhousesView()
                            .frame(width: 150, height: 160)
                            .padding()
                            .background(Color.white.cornerRadius(20))
                        }
                        
                        NavigationLink {
                            AddHenhousesView(vm: vm)
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .foregroundStyle(.white)
                                HStack {
                                    Image(systemName: "plus")
                                    Text("Add Henhouse")
                                    
                                }
                                .padding()
                                .font(.headline)
                                .foregroundStyle(.black)
                            }
                        }

                        if vm.hendoses.isEmpty {
                            Text("No Henhouses yet")
                        }
                        ForEach(vm.hendoses) { hendose in
                            CellForHenhousesView(henhous: hendose, action: {
                                ///delete action
                            }, day7: 0, day30: 0)
                        }
                    }.padding()
                }
                
            }
            .navigationTitle("Henhouses")
        }
    }
}

#Preview {
    HenhousesView()
}

struct StatisticOfHenhousesView: View {
    var body: some View {
        Text("StatisticOfHenhousesView")
    }
}
