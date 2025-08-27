//
//  AddLogView.swift
//  MyHenFarm2
//
//  Created by Роман Главацкий on 26.08.2025.
//

import SwiftUI

struct AddLogView: View {
    @StateObject var vm: HomeViewModel
    @FocusState var isFocused: Bool
    var body: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
                .onTapGesture {
                    vm.isPresentAddLog.toggle()
                }
            VStack {
                Text("Add log")
                    .font(.title)
                VStack(alignment: .leading) {
                    Text("Date:")
                        .font(.headline)
                    DatePicker("", selection: $vm.simpleDateLog)
                }
                VStack(alignment: .leading) {
                    Text("Stepper")
                        .font(.headline)
                    TextField("0", text: $vm.simpleCountLog)
                        .focused($isFocused)
                        .padding(10)
                        .background {
                            Color.white.cornerRadius(10)
                        }
                        .keyboardType(.numberPad)
                }
                VStack(alignment: .leading) {
                    Text("HenHouse:")
                        .font(.headline)
                    Menu {
                        ForEach(vm.coopList) { coop in
                            Button {
                                vm.simpleCoopLog = coop
                            } label: {
                                Text(coop.name ?? "")
                            }

                        }
                    } label: {
                        HStack {
                            Text(vm.simpleCoopLog?.name ?? "Select coop")
                            Spacer()
                            Image(systemName: "chevron.down")
                        }
                        .foregroundStyle(.black)
                        .padding(10)
                        .background {
                            Color.white.cornerRadius(10)
                        }
                    }

                }
                VStack(alignment: .leading) {
                    Text("Notes:")
                        .font(.headline)
                    ZStack(alignment: .topLeading)  {
                        TextEditor(text: $vm.simpleNoteLog)
                            .frame(height: 100)
                            .padding(10)
                            .background(Color.white.cornerRadius(10))
                            .focused($isFocused)
                        if vm.simpleNoteLog.isEmpty {
                            Text("Add notes...")
                                .foregroundColor(.gray)
                                .padding()
                        }
                    }
                }
                Button {
                    vm.addLogEgg()
                    vm.isPresentAddLog.toggle()
                } label: {
                    GreenButtonView(title: "Save")
                        .opacity(vm.simpleCountLog != "" ? 1 : 0.3)
                }.disabled(vm.simpleCountLog == "")

            }
            .frame(width: 250)
            .padding()
            .background(Color.white
                .opacity(0.8)
                .cornerRadius(20))
        }
        .onTapGesture {
            isFocused = false
        }
    }
}

#Preview {
    AddLogView(vm: HomeViewModel())
}
