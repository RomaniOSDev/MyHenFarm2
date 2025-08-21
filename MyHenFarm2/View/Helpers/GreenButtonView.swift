//
//  GreenButtonView.swift
//  MyHenFarm2
//
//  Created by Роман Главацкий on 21.08.2025.
//

import SwiftUI

struct GreenButtonView: View {
    let title: String
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .foregroundStyle(.greenApp)
                .frame(maxHeight: 51)
            Text(title)
                .font(.title3)
                .bold()
                .foregroundStyle(.white)
        }
            
    }
}

#Preview {
    GreenButtonView(title: "Next")
}
