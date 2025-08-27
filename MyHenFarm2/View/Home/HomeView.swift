//
//  HomeView.swift
//  MyHenFarm2
//
//  Created by Роман Главацкий on 21.08.2025.
//

import SwiftUI

struct HomeView: View {
    @StateObject var vm = HomeViewModel()
    var body: some View {
        NavigationStack {
            ZStack {
                Color.mainColorApp.ignoresSafeArea()
                ScrollView {
                    VStack {
                        VStack {
                            HStack {
                                Text("Today")
                                    .font(.title)
                                    .bold()
                                Spacer()
                            }
                            Image(.egg)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 120)
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .resizable()
                                    .frame(width: 32, height: 32)
                                
                                Text("Fed")
                                    .font(.title3)
                            }
                            .foregroundStyle(.white)
                            .padding(10)
                            .padding(.horizontal)
                            .background(Color.greenApp.cornerRadius(20))
                            
                            //MARK: - Add button
                            HStack {
                                NavigationLink {
                                    AddEggsView(vm: vm)
                                } label: {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 20)
                                            .foregroundStyle(Color.gray.opacity(0.2))
                                        
                                        HStack {
                                            Image(systemName: "plus")
                                            
                                            Text("Add eggs")
                                                .font(.title3)
                                        }
                                        .foregroundStyle(.black)
                                    }
                                    
                                }
                                
                                NavigationLink {
                                    FeedingForMyFarmView(vm: vm)
                                } label: {
                                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                                            .foregroundStyle(Color.gray.opacity(0.2))
                                            
                                        Text("Feeding")
                                            .font(.title3)
                                            .padding()
                                    }
                                    .foregroundStyle(.black)
                                    
                                }

                            }
                        }
                        .padding()
                        .background(Color.white.cornerRadius(20))
                        
                        NavigationLink {
                            AggsFeedingStatisticView()
                        } label: {
                            Image(.table)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        }

                        
                            
                        
                    }.padding()
                }
                
            }
            .navigationTitle("Home")
        }
    }
}

#Preview {
    HomeView()
}
