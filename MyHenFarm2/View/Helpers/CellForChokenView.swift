//
//  CellForChokenView.swift
//  MyHenFarm2
//
//  Created by Роман Главацкий on 21.08.2025.
//

import SwiftUI

struct CellForChokenView: View {
    let chiken: Chiken
    let action: () -> Void
    var body: some View {
        HStack(spacing: 40) {
            if let image = convertDataToImage(chiken.photo) {
                Image(uiImage: image)
                    .resizable()
                    .frame(width: 90, height: 90)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }else {
                Text("No Image")
                    .frame(width: 90, height: 90)
            }
            
            
            VStack(alignment: .leading) {
                Text(chiken.name ?? "no name")
                    .font(.headline)
                    .foregroundStyle(.black)
                Text(chiken.breed ?? "no breed")
                    .font(.callout)
                    .foregroundStyle(.gray)
                Text("Age \(chiken.age)")
                    .font(.callout)
                    .foregroundStyle(.gray)
            }
            Spacer()
            
            Button {
                action()
            } label: {
                Image(systemName: "trash.fill")
                    .foregroundStyle(.red)
            }

        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 10)
                .foregroundStyle(.white)
                .shadow(radius: 5)
        }
        .padding()
    }
    
    private func convertDataToImage(_ data: Data?) -> UIImage? {
        guard let data else { return nil }
        return UIImage(data: data)
    }
}

#Preview {
    CellForChokenView(chiken: Chiken(context: CoreDataManager.instance.context), action: {})
}
