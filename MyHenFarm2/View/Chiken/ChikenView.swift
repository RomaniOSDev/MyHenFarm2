//
//  ChikenView.swift
//  MyHenFarm2
//
//  Created by Роман Главацкий on 21.08.2025.
//

import SwiftUI

struct ChikenView: View {
    @StateObject var viewModel = ChikenViewmodel()
    var body: some View {
        NavigationStack {
            ZStack {
                Color.mainColorApp.ignoresSafeArea()
                VStack {
                    ScrollView {
                        if viewModel.chikens.isEmpty {
                            Text("No chikens")
                        }else{
                            ForEach(viewModel.chikens) { chiken in
                                CellForChokenView(chiken: chiken, action: {
                                    viewModel.deleteChiken(chiken: chiken)
                                })
                            }
                        }
                    }
                    Button {
                        viewModel.isPresenrAddView.toggle()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .foregroundStyle(.blue)
                    }
                    
                }.padding()
            }
            .navigationDestination(isPresented: $viewModel.isPresenrAddView, destination: {
                AddChikenView(vm: viewModel)
            })
            .navigationTitle("Chikens")
        }
    }
}

#Preview {
    ChikenView()
}
