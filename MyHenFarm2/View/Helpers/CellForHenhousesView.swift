//
//  CellForHenhousesView.swift
//  MyHenFarm2
//
//  Created by Роман Главацкий on 22.08.2025.
//

import SwiftUI

struct CellForHenhousesView: View {
    let henhous: Coop
    let action: () -> Void
    let day7: Int
    let day30: Int
    
    var body: some View {
        HStack(spacing: 40) {
            if let image = convertDataToImage(henhous.photo) {
                Image(uiImage: image)
                    .resizable()
                    .frame(width: 90, height: 90)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }else {
                Text("No Image")
                    .frame(width: 90, height: 90)
                
            }
            
            
            VStack(alignment: .leading) {
                HStack {
                    Text(henhous.name ?? "no name")
                        .font(.headline)
                        .foregroundStyle(.black)
                    Spacer()
                    
                    Button {
                        action()
                    } label: {
                        Image(systemName: "trash.fill")
                            .foregroundStyle(.red)
                    }
                }
                if let chikens = henhous.chiken?.allObjects as? [Chiken] {
                    Text("\(chikens.count) chikens")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
                HStack{
                    Text("\(day7) 7 day")
                        .foregroundStyle(.gray)
                    Spacer()
                    Text("\(day30) 30 day")
                        .foregroundStyle(.gray)
                }
                Text("Bilding: \(Dateformatter(date: henhous.bildday ?? Date()))")
                
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
    //MARK: - Dateformatter
    private func Dateformatter(date: Date) -> String{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        return dateFormatter.string(from: date)
    }
}

#Preview {
    CellForHenhousesView(henhous: Coop(context: CoreDataManager.instance.context), action: {}, day7: 0, day30: 0)
}
