//
//  CustomTimePickerView.swift
//  MyHenFarm2
//
//  Created by Роман Главацкий on 22.08.2025.
//

import SwiftUI

struct CustomTimePickerView: View {
    @Binding var selectedTime: Date
    @State private var selectedHour: Int
    @State private var selectedMinute: Int
    @State private var isAM: Bool
    @State private var showingTimePicker = false
    
    init(selectedTime: Binding<Date>) {
        self._selectedTime = selectedTime
        
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: selectedTime.wrappedValue)
        let minute = calendar.component(.minute, from: selectedTime.wrappedValue)
        
        self._selectedHour = State(initialValue: hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour))
        self._selectedMinute = State(initialValue: minute)
        self._isAM = State(initialValue: hour < 12)
    }
    
    var body: some View {
        HStack(spacing: 20) {
            // Hours
            VStack(spacing: 8) {
                Text("HOURS")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                
                Button(action: {
                    showingTimePicker = true
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.pinkApp)
                            .frame(width: 80, height: 120)
                        
                        VStack(spacing: 0) {
                            Spacer()
                            
                            Text("\(selectedHour)")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                                .frame(width: 60, height: 50)
                            
                            Spacer()
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Minutes
            VStack(spacing: 8) {
                Text("MINUTES")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                
                Button(action: {
                    showingTimePicker = true
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.pinkApp)
                            .frame(width: 80, height: 120)
                        
                        VStack(spacing: 0) {
                            Spacer()
                            
                            Text("\(String(format: "%02d", selectedMinute))")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .frame(width: 60, height: 50)
                            
                            Spacer()
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // AM/PM Toggle
            VStack(spacing: 8) {
                Text("AM/PM")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 80, height: 120)
                    
                    VStack(spacing: 8) {
                        Button(action: {
                            isAM = true
                            updateTimeFromLocalValues()
                        }) {
                            Text("AM")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 40)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(isAM ? Color.blue : Color.gray)
                                )
                        }
                        
                        Button(action: {
                            isAM = false
                            updateTimeFromLocalValues()
                        }) {
                            Text("PM")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 40)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(!isAM ? Color.orange : Color.gray)
                                )
                        }
                    }
                    .padding(.top, 20)
                }
            }
        }
        .padding()
        .onChange(of: selectedTime) { newTime in
            print("⏰ selectedTime changed to: \(newTime)")
            updateFromSelectedTime()
        }
        .sheet(isPresented: $showingTimePicker) {
            TimePickerSheet(selectedTime: $selectedTime, selectedHour: $selectedHour, selectedMinute: $selectedMinute, isAM: $isAM)
        }
        .onAppear {
            updateFromSelectedTime()
        }
    }
    
    // MARK: - Private Methods
    
    private func updateTimeFromLocalValues() {
        var hour = selectedHour
        
        // Convert to 24-hour format
        if !isAM && selectedHour != 12 {
            hour += 12
        } else if isAM && selectedHour == 12 {
            hour = 0
        }
        
        let calendar = Calendar.current
        if let newDate = calendar.date(bySettingHour: hour, minute: selectedMinute, second: 0, of: selectedTime) {
            print("🕐 Updating time from local values: \(hour):\(selectedMinute) \(isAM ? "AM" : "PM")")
            selectedTime = newDate
        }
    }
    
     func updateFromSelectedTime() {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: selectedTime)
        let minute = calendar.component(.minute, from: selectedTime)
        
        let newHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour)
        let newIsAM = hour < 12
        
        print("🔄 Updating local values from time: \(hour):\(minute) -> \(newHour):\(minute) \(newIsAM ? "AM" : "PM")")
        
        selectedHour = newHour
        selectedMinute = minute
        isAM = newIsAM
    }
}

// MARK: - Preview
// MARK: - Time Picker Sheet
struct TimePickerSheet: View {
    @Binding var selectedTime: Date
    @Binding var selectedHour: Int
    @Binding var selectedMinute: Int
    @Binding var isAM: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Select Time")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top)
                
                DatePicker("Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(WheelDatePickerStyle())
                    .labelsHidden()
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
    

}

#Preview {
    CustomTimePickerView(selectedTime: .constant(Date()))
        .preferredColorScheme(.light)
}

#Preview {
    CustomTimePickerView(selectedTime: .constant(Date()))
        .preferredColorScheme(.dark)
}
