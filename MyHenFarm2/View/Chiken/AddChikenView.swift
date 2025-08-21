//
//  AddChikenView.swift
//  MyHenFarm2
//
//  Created by Роман Главацкий on 21.08.2025.
//

import SwiftUI
import PhotosUI

struct AddChikenView: View {
    @StateObject var vm: ChikenViewmodel
    @FocusState var isFocused: Bool

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
                
                //MARK: - Breed
                VStack(alignment: .leading) {
                    Text("Breed")
                        .font(.headline)
                    TextField("Enter breed", text: $vm.simplebreed)
                        .focused($isFocused)
                        .padding(8)
                        .background(Color.white.cornerRadius(8))
                }
                .foregroundStyle(.black)
                
                //MARK: - Age
                VStack(alignment: .leading) {
                    Text("Age")
                        .font(.headline)
                    TextField("Enter age", text: $vm.simpleage)
                        .focused($isFocused)
                        .keyboardType(.numberPad)
                        .padding(8)
                        .background(Color.white.cornerRadius(8))
                }
                .foregroundStyle(.black)
                
                Spacer()
                Button {
                    vm.tapAdd()
                } label: {
                    GreenButtonView(title: "Save")
                        .opacity(vm.simplename.isEmpty ? 0.5 : 1)
                }.disabled(vm.simplename.isEmpty)

            }
            .padding()
        }
        .onDisappear {
            vm.clearData()
        }
        .onTapGesture {
            isFocused.toggle()
        }
    }
}

#Preview {
    AddChikenView(vm: ChikenViewmodel())
}
