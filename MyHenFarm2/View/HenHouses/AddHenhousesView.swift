//
//  AddHenhousesView.swift
//  MyHenFarm2
//
//  Created by Роман Главацкий on 22.08.2025.
//

import SwiftUI
import PhotosUI

struct AddHenhousesView: View {
    
    @StateObject var vm: HendosesViewModel
    @FocusState var isFocused: Bool
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.mainColorApp.ignoresSafeArea()
            
            VStack {
                
                //MARK: Photo
                PhotosPicker(selection: $vm.selectedPhoto) {
                    if let photo = vm.simpleimage {
                        Image(uiImage: photo)
                            .resizable()
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .frame(width: 150, height: 150)
                            .aspectRatio(contentMode: .fit)
                        
                        
                    }
                    else{
                        Image(systemName: "plus.rectangle.fill")
                            .resizable()
                            .frame(width: 150, height: 150)
                    }
                }
                .onChange(of: vm.selectedPhoto) { newValue in
                    Task {
                        if let data = try? await newValue?.loadTransferable(type: Data.self) {
                            if let image = UIImage(data: data) {
                                vm.simpleimage = image
                            }
                        }
                    }
                }
                ScrollView{
                    //MARK: - Name
                    VStack(alignment: .leading) {
                        Text("Name")
                            .font(.headline)
                        TextField("Enter name", text: $vm.simplename)
                            .padding(8)
                            .background(Color.white.cornerRadius(8))
                            .focused($isFocused)
                    }
                    .foregroundStyle(.black)
                    
                    //MARK: - Date and Time
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Date & Time")
                            .font(.headline)
                            .foregroundStyle(.black)
                        
                        // Date picker
                        DatePicker("Date", selection: $vm.simpleDate, displayedComponents: .date)
                            .padding()
                            .background(Color.white.cornerRadius(8))
                        
                        // Custom time picker
                        CustomTimePickerView(selectedTime: $vm.simpleDate)
                            .padding()
                            .background(Color.white.cornerRadius(8))
                    }
                    .padding(.vertical)
                    
                    //MARK: - Chiken
                    Button {
                        vm.isPresentedChikenLists.toggle()
                    } label: {
                        ZStack{
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(lineWidth: 2)
                                .foregroundStyle(.greenApp)
                            
                            Text("+")
                        }
                        .frame(height: 50)
                    }

                    
                    ForEach(vm.simppleChikenList) { chiken in
                        HStack{
                            Text(chiken.name ?? "")
                            
                            Text(chiken.breed ?? "")
                            Spacer()
                            Button {
                                vm.removeChikenFromHendose(chiken: chiken)
                            } label: {
                                Image(systemName: "xmark")
                            }

                        }
                        .foregroundStyle(.black)
                        .padding()
                        .background {
                            Color.white.cornerRadius(8)
                                .shadow(radius: 5)
                        }
                        .padding()
                    }
                    
                }
                
                
               
                Button {
                    vm.addNewHendose()
                    dismiss()
                    
                } label: {
                    GreenButtonView(title: "Save")
                        .opacity(vm.simplename.isEmpty ? 0.5 : 1)
                }.disabled(vm.simplename.isEmpty)
                
            }
            .padding()
        }
        .sheet(isPresented: $vm.isPresentedChikenLists, content: {
            BirdsListsview(vm: vm)
        })
        .onDisappear {
            vm.clearSimpleData()
        }
        .onTapGesture {
            isFocused.toggle()
        }
    }
}

#Preview {
    AddHenhousesView(vm: HendosesViewModel())
}
