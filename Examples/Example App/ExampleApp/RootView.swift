// By Dennis Müller

import SwiftUI

struct RootView: View {
  @State private var randomNumbers: [Int] = []

  var body: some View {
    NavigationStack {
      List(randomNumbers, id: \.self) { number in
        NavigationLink(value: number) {
          HStack {
            Text("\(number)")
              .font(.title2)
              .fontWeight(.medium)

            Spacer()

            Image(systemName: "chevron.right")
              .foregroundStyle(.secondary)
              .font(.caption)
          }
        }
      }
      .navigationTitle("Random Numbers")
      .navigationDestination(for: Int.self) { number in
        NumberDetailView(number: number)
      }
      .task {
        await generateRandomNumbers()
      }
      .refreshable {
        await generateRandomNumbers()
      }
    }
    .safeAreaBar(edge: .bottom) {
      Text("Hello")
    }
  }

  private func generateRandomNumbers() async {
    randomNumbers = (0..<20).map { _ in Int.random(in: 1...1000) }
  }
}

#Preview {
  RootView()
}
