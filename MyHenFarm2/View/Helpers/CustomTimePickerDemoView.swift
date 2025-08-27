//
//  CustomTimePickerDemoView.swift
//  MyHenFarm2
//
//  Created by Роман Главацкий on 22.08.2025.
//

import SwiftUI

struct CustomTimePickerDemoView: View {
    @State private var selectedTime = Date()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.mainColorApp.ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Custom Time Picker")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Select time with large digits and AM/PM toggle")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Current selected time display
                    VStack(spacing: 12) {
                        Text("Selected Time")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(timeFormatter.string(from: selectedTime))
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.blue)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white)
                                    .shadow(radius: 5)
                            )
                    }
                    
                    // Custom Time Picker
                    CustomTimePickerView(selectedTime: $selectedTime)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white)
                                .shadow(radius: 10)
                        )
                    
                    // Quick time presets
                    VStack(spacing: 16) {
                        Text("Quick Presets")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 16) {
                            TimePresetButton(title: "Morning", time: "09:00", action: { setPresetTime(hour: 9, minute: 0, isAM: true) })
                            TimePresetButton(title: "Noon", time: "12:00", action: { setPresetTime(hour: 12, minute: 0, isAM: true) })
                            TimePresetButton(title: "Evening", time: "18:00", action: { setPresetTime(hour: 6, minute: 0, isAM: false) })
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - Private Methods
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
    
    private func setPresetTime(hour: Int, minute: Int, isAM: Bool) {
        let calendar = Calendar.current
        var adjustedHour = hour
        
        if !isAM && hour != 12 {
            adjustedHour += 12
        } else if isAM && hour == 12 {
            adjustedHour = 0
        }
        
        if let newDate = calendar.date(bySettingHour: adjustedHour, minute: minute, second: 0, of: selectedTime) {
            selectedTime = newDate
        }
    }
}

// MARK: - Time Preset Button
struct TimePresetButton: View {
    let title: String
    let time: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(time)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.blue)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(radius: 3)
            )
        }
    }
}

// MARK: - Preview
#Preview {
    CustomTimePickerDemoView()
}
