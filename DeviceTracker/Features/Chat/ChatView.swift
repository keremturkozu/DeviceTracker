import SwiftUI

struct ChatView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ChatViewModel
    @FocusState private var isInputFocused: Bool
    
    init(device: Device) {
        _viewModel = StateObject(wrappedValue: ChatViewModel(device: device))
    }
    
    var body: some View {
        ZStack {
            // Background
            Theme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Chat messages
                ScrollViewReader { scrollProxy in
                    ScrollView {
                        LazyVStack(spacing: 15) {
                            ForEach(viewModel.messages, id: \.id) { message in
                                MessageBubble(message: message)
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                    }
                    .onChange(of: viewModel.messages.count) { oldCount, newCount in
                        if let lastMessage = viewModel.messages.last {
                            withAnimation {
                                scrollProxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Message input
                HStack(spacing: 15) {
                    TextField("Message Here", text: $viewModel.messageText)
                        .padding(12)
                        .background(Color.white)
                        .cornerRadius(20)
                        .focused($isInputFocused)
                    
                    Button {
                        viewModel.sendMessage()
                    } label: {
                        HStack {
                            Image(systemName: "photo")
                                .foregroundColor(.white)
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.white)
                        }
                        .padding(12)
                        .background(Theme.primary)
                        .cornerRadius(20)
                        .shadow(color: Theme.shadowColor, radius: Theme.shadowRadius, x: Theme.shadowX, y: Theme.shadowY)
                    }
                    .disabled(viewModel.messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.9))
                .shadow(color: Theme.shadowColor, radius: 2, x: 0, y: -1)
            }
        }
        .navigationTitle(viewModel.device.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(Theme.primary)
                        .imageScale(.large)
                }
            }
        }
        .alert(item: Binding<AlertItem?>(
            get: {
                guard let errorMessage = viewModel.errorMessage else { return nil }
                return AlertItem(message: errorMessage)
            },
            set: { _ in viewModel.errorMessage = nil }
        )) { alert in
            Alert(title: Text("Error"), message: Text(alert.message), dismissButton: .default(Text("OK")))
        }
        .onTapGesture {
            isInputFocused = false
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer()
                Text(message.content)
                    .padding(12)
                    .background(Theme.primary)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(
                        Image(systemName: "arrowtriangle.right.fill")
                            .foregroundColor(Theme.primary)
                            .rotationEffect(.degrees(90))
                            .offset(x: 8, y: 0),
                        alignment: .bottomTrailing
                    )
                    .shadow(color: Theme.shadowColor, radius: Theme.shadowRadius, x: Theme.shadowX, y: Theme.shadowY)
            } else {
                Text(message.content)
                    .padding(12)
                    .background(Color.white)
                    .foregroundColor(Theme.text)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(
                        Image(systemName: "arrowtriangle.left.fill")
                            .foregroundColor(.white)
                            .rotationEffect(.degrees(90))
                            .offset(x: -8, y: 0),
                        alignment: .bottomLeading
                    )
                    .shadow(color: Theme.shadowColor, radius: Theme.shadowRadius, x: Theme.shadowX, y: Theme.shadowY)
                Spacer()
            }
        }
        .id(message.id)
    }
}

#Preview {
    NavigationStack {
        ChatView(device: Device(name: "MacBook Pro", distance: 0.8))
    }
} 