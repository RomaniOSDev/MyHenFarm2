//
//  AddEggsView.swift
//  MyHenFarm2
//
//  Created by Роман Главацкий on 26.08.2025.
//

import SwiftUI

struct AddEggsView: View {
    @StateObject var vm: HomeViewModel
    var body: some View {
        ZStack {
            Color.mainColorApp.ignoresSafeArea()
            VStack {
                Menu {
                    Button {
                        vm.sortingCopp = nil
                    } label: {
                        Text("All")
                    }
                    ForEach(vm.coopList) { coop in
                        Button {
                            print("🔄 Selected coop: \(coop.name ?? "unknown")")
                            vm.sortingCopp = coop
                            print("✅ sortingCopp set to: \(vm.sortingCopp?.name ?? "nil")")
                        } label: {
                            Text(coop.name ?? "")
                        }
                    }
                } label: {
                    HStack {
                        Text(vm.sortingCopp?.name ?? "Choose coop")
                        Spacer()
                        Image(systemName: "chevron.down")
                    }
                    .foregroundStyle(.black)
                    .padding()
                    .background {
                        Color.white.cornerRadius(8)
                    }
                }

                ScrollView {
                    ForEach(vm.sortedEggsLog) { log in
                        CellForLogView(log: log) {
                            vm.deleteEggLog(log)
                        }
                    }
                }
                //MARK: - Add button
                Button {
                    vm.isPresentAddLog.toggle()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .foregroundStyle(.blue)
                        
                }

            }
            .padding()
            if vm.isPresentAddLog {
                AddLogView(vm: vm)
            }
        }
        .onAppear(perform: {
            vm.getFeedings()
        })
        .onDisappear {
            vm.clearLogsSimpleData()
        }
    }
}

#Preview {
    AddEggsView(vm: HomeViewModel())
}
