//
//  AddEggsForMyView.swift
//  MyHenFarm2
//
//  Created by Роман Главацкий on 25.08.2025.
//

import SwiftUI

struct AddFeedingForMyFarmView: View {
    
    @StateObject var vm: HomeViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.mainColorApp.ignoresSafeArea()
            VStack(spacing: 20) {
                ScrollView {
                    
                    //MARK: - Time
                    VStack(alignment: .leading) {
                        Text("Time").font(.headline)
                        CustomTimePickerView(selectedTime: $vm.simpleTime)
                    }
                    
                    //MARK: - Coops
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Choose HenHouse").font(.headline)
                            Spacer()
                        }
                        if vm.coopList.isEmpty {
                            Text("No Henhouses. Please add one")
                        }else{
                            LazyHGrid(rows: [GridItem(),GridItem()]) {
                                ForEach(vm.coopList , id: \.self) { coop in
                                    Button {
                                        vm.simpleCoop = coop
                                    } label: {
                                        Text(coop.name ?? "")
                                            .foregroundStyle(.black)
                                            .padding(10)
                                            .padding(.horizontal)
                                            .background {
                                                Color.green
                                                    .cornerRadius(10)
                                                    .opacity(vm.simpleCoop == coop ? 1.0 : 0.3)
                                            }
                                    }
                                    
                                    
                                }
                            }
                        }
                    }
                    
                    //MARK: - Type of feeding
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Type of feed").font(.headline)
                            Spacer()
                        }
                        LazyHGrid(rows: [GridItem(),GridItem()]) {
                            ForEach(FeedingType.allCases , id: \.self) { type in
                                Button {
                                    vm.simpleType = type
                                } label: {
                                    Text(type.title)
                                        .foregroundStyle(.black)
                                        .padding(10)
                                        .padding(.horizontal)
                                        .background {
                                            type.color.cornerRadius(20)
                                                .opacity(vm.simpleType == type ? 1.0 : 0.3)
                                        }
                                }
                                
                                
                            }
                        }
                    }
                    
                    //MARK: - Type
                    VStack(alignment: .leading) {
                        Text("Note").font(.headline)
                        ZStack(alignment: .topLeading) {
                            
                            TextEditor(text: $vm.simpleNote)
                                .frame(minHeight: 80)
                            if vm.simpleNote.isEmpty {
                                Text("Add note").foregroundColor(.gray)
                                    .padding(.top, 10)
                            }
                        }
                        .padding()
                        .background {
                            Color.white.cornerRadius(20)
                        }
                        .frame(minHeight: 200)
                        
                        
                    }
                }
                Spacer()
                
                //MARK: - Save button
                Button {
                    vm.addFeeding()
                    dismiss()
                } label: {
                    GreenButtonView(title: "Save")
                        .opacity(vm.simpleCoop == nil ? 0.5 : 1.0)
                }.disabled(vm.simpleCoop == nil)
                
            }.padding()
            
        }
        .navigationTitle("Feeding")
        .onDisappear {
            vm.clearSimpleData()
        }
    }
}

#Preview {
    AddFeedingForMyFarmView(vm: HomeViewModel())
}

