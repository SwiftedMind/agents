// By Dennis Müller

import SwiftUI

struct NumberDetailView: View {
  var number: Int
  
  var body: some View {
    VStack(spacing: 24) {
      Spacer()
      
      Text("\(number)")
        .font(.system(size: 120, weight: .bold, design: .rounded))
        .foregroundStyle(.primary)
        .monospacedDigit()
      
      Text("Your Selected Number")
        .font(.title2)
        .foregroundStyle(.secondary)
      
      Spacer()
    }
    .navigationTitle("Number Detail")
    .navigationBarTitleDisplayMode(.inline)
  }
}

#Preview {
  NavigationStack {
    NumberDetailView(number: 742)
  }
}