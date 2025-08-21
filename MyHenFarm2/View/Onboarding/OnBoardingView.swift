//
//  OnBoardingView.swift
//  MyHenFarm2
//
//  Created by Роман Главацкий on 21.08.2025.
//

import SwiftUI

struct OnBoardingView: View {
    @ObservedObject private var viewModel = OnBoardingViewModel()
    var body: some View {
        ZStack {
            Color.mainColorApp
                .ignoresSafeArea()
            VStack(spacing: 60) {
                Spacer()
                Image(viewModel.getCurrentPage().image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                Text(viewModel.getCurrentPage().title)
                    .font(.title)
                    .fontWeight(.bold)
                Spacer()
                
                Button {
                    viewModel.tapToNextPage()
                } label: {
                    GreenButtonView(title: viewModel.currentPage == viewModel.pages.count - 1 ? "Play" : "Next")
                }
                .padding(.horizontal, 40)

                
            }.padding()
        }
        .fullScreenCover(isPresented: $viewModel.ispresent) {
            MainView()
        }
    }
}

#Preview {
    OnBoardingView()
}

final class OnBoardingViewModel: ObservableObject {
    @Published var currentPage: Int = 0
    @Published var ispresent: Bool = false
    @AppStorage("comlitedOnboarding") var isComlitedOnboarding: Bool?
    
    var pages: [OnBoardPage] = []
    
    init(){
        pages = [OnBoardPage(title: "Welcome", image: .onboagrImage1),
                 OnBoardPage(title: "Welcome", image: .onboardimage2),
                 OnBoardPage(title: "Welcome", image: .onboardimage3)]
    }
    
    func getCurrentPage() -> OnBoardPage{
        return pages[currentPage]
    }
    
    func tapToNextPage(){
        if currentPage == pages.count - 1{
            ispresent = true
            isComlitedOnboarding = true
        }
        else{
            currentPage += 1
        }
    }
}

struct OnBoardPage{
    let title: String
    let image: ImageResource
}
