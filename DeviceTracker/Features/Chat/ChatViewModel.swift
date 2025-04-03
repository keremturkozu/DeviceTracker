import Foundation
import Combine

class ChatViewModel: ObservableObject {
    // MARK: - Properties
    let device: Device
    
    @Published var messages: [ChatMessage] = []
    @Published var messageText: String = ""
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(device: Device) {
        self.device = device
        
        // Load existing chat history
        self.messages = device.chatHistory
        
        // If no messages exist, create a welcome message
        if messages.isEmpty {
            let welcomeMessage = ChatMessage(
                content: "Hello! This is the owner of \(device.name). How can I help you?",
                isFromUser: false
            )
            messages.append(welcomeMessage)
            device.chatHistory.append(welcomeMessage)
        }
    }
    
    // MARK: - Methods
    func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        // Create new message
        let newMessage = ChatMessage(content: messageText, isFromUser: true)
        
        // Add to list and clear input
        messages.append(newMessage)
        device.chatHistory.append(newMessage)
        messageText = ""
        
        // Simulate response after short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            
            // Create a simulated response
            let response = ChatMessage(
                content: self.generateResponse(),
                isFromUser: false
            )
            
            self.messages.append(response)
            self.device.chatHistory.append(response)
        }
    }
    
    // MARK: - Private Methods
    private func generateResponse() -> String {
        // In a real app, this would be a real message from the other device
        // For the demo, we'll just use some canned responses
        let responses = [
            "Thanks for your message! I'll get back to you soon.",
            "I found my device! Thank you.",
            "Hello, I'm the owner of this device. Can you help me find it?",
            "I'm nearby, I'll come get it soon.",
            "Thanks for letting me know!"
        ]
        
        return responses.randomElement() ?? "Message received!"
    }
} 