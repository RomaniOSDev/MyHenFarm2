//
//  MainView.swift
//  MyHenFarm2
//
//  Created by Роман Главацкий on 21.08.2025.
//

import SwiftUI

struct MainView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    VStack {
                        Image(systemName: "house")
                        Text("Home")
                    }
                }
            HenhousesView()
                .tabItem {
                    VStack {
                        Image(systemName: "circle.grid.3x3")
                        Text("Henhouses")
                    }
                }
            ChikenView()
                .tabItem {
                    VStack {
                        Image(systemName: "bird")
                        Text("Chiken")
                    }
                }
            StatisticOfHenhousesView()
                .tabItem {
                    VStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                        Text("Statistics")
                    }
                }
            SettingsView()
                .tabItem {
                    VStack {
                        Image(systemName: "gear")
                        Text("Settings")
                    }
                }
        }
    }
}

#Preview {
    MainView()
}
