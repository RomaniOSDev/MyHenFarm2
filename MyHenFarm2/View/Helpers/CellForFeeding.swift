//
//  CellForFeeding.swift
//  MyHenFarm2
//
//  Created by Роман Главацкий on 26.08.2025.
//

import SwiftUI

struct CellForFeeding: View {
    let feeding: Feeding
    let deleteAction: () -> Void
    
    var body: some View {
        VStack {
            HStack {
                Text(Dateformatter(date: feeding.time ?? Date()))
                    .font(.system(size: 21, weight: .bold))
                VStack(alignment: .leading) {
                    Text(feeding.type ?? "")
                        .font(.system(size: 17))
                        .padding(10)
                        .background {
                            RoundedRectangle(cornerRadius: 20)
                                .foregroundStyle(.accent)
                        }
                    if let coop = feeding.coop {
                        Text("\(coop.name ?? "")")
                            .font(.system(size: 17))
                    }
                }
                Spacer()
                Button {
                    deleteAction()
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }

            }
            
            Rectangle()
                .frame(height: 1)
        }
        .padding()
    }
    //MARK: - Dateformatter
    private func Dateformatter(date: Date) -> String{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:MM"
        return dateFormatter.string(from: date)
    }
}

#Preview {
    CellForFeeding(feeding: Feeding(context: CoreDataManager.instance.context), deleteAction: {})
}
