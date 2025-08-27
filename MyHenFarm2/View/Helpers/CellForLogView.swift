//
//  CellForLogView.swift
//  MyHenFarm2
//
//  Created by Роман Главацкий on 26.08.2025.
//

import SwiftUI

struct CellForLogView: View {
    let log: EggsLog
    let deleteLog: () -> Void
    var body: some View {
        HStack {
            VStack {
                Text(Dateformatter(date: log.date ?? Date()))
                Button {
                    deleteLog()
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }

            }
            Spacer()
            Text("\(log.countEggs)")
            if let coop = log.coop {
                Text(coop.name ?? "")
                    .padding(10)
                    .background(Color.gray)
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(Color.white.cornerRadius(10))
        .shadow(radius: 5)
        .padding()
    }
    //MARK: - Dateformatter
    private func Dateformatter(date: Date) -> String{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM dd"
        return dateFormatter.string(from: date)
    }
}

#Preview {
    CellForLogView(log: EggsLog(context: CoreDataManager.instance.context), deleteLog: {})
}
