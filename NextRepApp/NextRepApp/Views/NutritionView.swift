import SwiftUI

struct NutritionView: View {
    var body: some View {
        VStack(spacing: 24) {
            Text("Nutrition")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Theme.text)
            
            Text("Track your nutrition and macros")
                .font(.system(size: 16))
                .foregroundColor(Theme.textDim)
            
            Spacer()
            
            Button("Add Entry") {
                // TODO: Add entry
            }
            .buttonStyle(PrimaryButton())
            .padding(.horizontal)
        }
        .padding()
        .navigationTitle("Nutrition")
        .navigationBarTitleDisplayMode(.inline)
    }
}