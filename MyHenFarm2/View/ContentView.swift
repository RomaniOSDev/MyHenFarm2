//
//  ContentView.swift
//  MyHenFarm2
//
//  Created by Роман Главацкий on 21.08.2025.
//

import SwiftUI

struct ContentView: View {
    
    @State private var percents: Int = 0
    @State private var isLoading: Bool = true 
    @State private var isShowNextView: Bool = false
    
    @AppStorage("comlitedOnboarding") var isComlitedOnboarding: Bool = false
    
    var body: some View {
        ZStack{
            Color.mainColorApp.ignoresSafeArea()
            VStack {
                Image(.logo)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(60)
                if isLoading {
                    ProgressView("\(percents)%")
                }
            }
        }
        .fullScreenCover(isPresented: $isShowNextView, content: {
            if isComlitedOnboarding {
                MainView()
            }else{
                OnBoardingView()
            }
        })
        .onAppear(perform: {
            Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { timer in
                if percents < 100{
                    percents += 1
                }else {
                    timer.invalidate()
                    endLoading()
                }
            }
        })
    }
    
    private func endLoading() {
        isLoading = false
        isShowNextView = true
    }
}

#Preview {
    ContentView()
}
