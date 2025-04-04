import Foundation
import SwiftUI
import StoreKit

/// StoreKit ile in-app satın alma işlemlerini yönetmek için Helper sınıf
class StoreKitHelper: ObservableObject {
    // Singleton pattern
    static let shared = StoreKitHelper()
    
    // Ürün tanımlayıcıları
    private let weeklySubscriptionID = "com.yourcompany.devicetracker.weekly_premium"
    
    // Ürünler
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs = Set<String>()
    
    /// App içi satın alımların durumunu izleyen property wrapper
    @AppStorage("isPremiumUser") private(set) var isPremiumUser: Bool = false
    
    // App Store ile aktif transaction listener'ı
    private var transactionListener: Task<Void, Error>?
    
    /// Singleton constructor - private yaparak dışarıdan erişimi engeller
    private init() {
        // StoreKit transaction listener'ı başlat
        transactionListener = listenForTransactions()
        
        // Ürünleri yükle
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }
    
    deinit {
        transactionListener?.cancel()
    }
    
    /// StoreKit transactions için listener başlatır
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            // Verification sonuçlarına göre işlem yaparız
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    
                    // İşlem tamamlandığında premium durumunu güncelle
                    await self.updatePurchasedProducts()
                    
                    // İşlemi sonlandır (onaylıyoruz)
                    await transaction.finish()
                } catch {
                    // Doğrulama hatası oluştu
                    print("Transaction failed verification: \(error)")
                }
            }
        }
    }
    
    /// App Store'dan ürünleri yükler
    @MainActor
    func loadProducts() async {
        do {
            // Tüm ürünleri ID'lere göre yükle
            let products = try await Product.products(for: [weeklySubscriptionID])
            self.products = products
            print("Loaded \(products.count) products")
            
            // Debug için ürün bilgilerini yazdır
            for product in products {
                print("Product: \(product.id), \(product.displayName), \(product.displayPrice)")
            }
        } catch {
            print("Failed to load products: \(error)")
            self.products = []
        }
    }
    
    /// Kullanıcının daha önce satın aldığı ürünleri kontrol eder
    @MainActor
    func updatePurchasedProducts() async {
        // Satın alınan ürünleri kontrol et
        var purchasedIDs = Set<String>()
        var isPremium = false
        
        // Satın alınan ürünleri App Store'dan kontrol et
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                // Güncel StoreKit versiyonunda, abonelik durumunu revocationDate ve expirationDate ile kontrol ediyoruz
                if transaction.productID == weeklySubscriptionID && !transaction.isUpgraded {
                    // Revocation date varsa iptal edilmiş abonelik
                    if transaction.revocationDate == nil {
                        // ExpirationDate kontrolü - nil veya gelecekte ise aktif abonelik
                        if let expirationDate = transaction.expirationDate {
                            // Sona erme tarihi gelecekteyse aktif
                            if expirationDate > Date() {
                                purchasedIDs.insert(transaction.productID)
                                isPremium = true
                            }
                        } else {
                            // ExpirationDate yoksa bu ömür boyu satın alınmış bir ürün
                            purchasedIDs.insert(transaction.productID)
                            isPremium = true
                        }
                    }
                }
            } catch {
                print("Error verifying transaction: \(error)")
            }
        }
        
        purchasedProductIDs = purchasedIDs
        isPremiumUser = isPremium
    }
    
    /// Bir ürünün satın alınma durumunu kontrol eder
    func isPurchased(_ productID: String) -> Bool {
        return purchasedProductIDs.contains(productID)
    }
    
    /// Haftalık premium aboneliğini satın alır
    @MainActor
    func purchasePremium() async throws -> Bool {
        // Ürünü bul
        guard let product = products.first(where: { $0.id == weeklySubscriptionID }) else {
            throw StoreError.productNotFound
        }
        
        do {
            // Ürün satın alınıyor
            let result = try await product.purchase()
            
            // Satın alma sonucunu kontrol et
            switch result {
            case .success(let verificationResult):
                // Doğrulama kontrolleri
                let transaction = try checkVerified(verificationResult)
                
                // Satın alınan ürünleri güncelle
                await updatePurchasedProducts()
                
                // İşlemi tamamla
                await transaction.finish()
                
                return isPremiumUser
                
            case .userCancelled:
                throw StoreError.userCancelled
                
            case .pending:
                throw StoreError.pending
                
            default:
                throw StoreError.unknown
            }
        } catch {
            // StoreError olmayan hataları sarmala
            if let storeError = error as? StoreError {
                throw storeError
            }
            throw StoreError.failedTransaction(error: error.localizedDescription)
        }
    }
    
    /// Eski satın alımları geri yükler
    @MainActor
    func restorePurchases() async throws -> Bool {
        // App Store'dan tüm satın alımları sorgula ve güncelle
        try await AppStore.sync()
        
        // Güncel satın alımları kontrol et
        await updatePurchasedProducts()
        
        // Premium durumunu döndür
        return isPremiumUser
    }
    
    /// StoreKit doğrulama sonuçlarını kontrol eder
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        // Doğrulama sonucunu kontrol et
        switch result {
        case .verified(let value):
            return value
        case .unverified:
            throw StoreError.failedVerification
        }
    }
}

/// StoreKit ile ilgili özel hata tipleri
enum StoreError: Error, LocalizedError {
    case productNotFound
    case failedVerification
    case userCancelled
    case pending
    case failedTransaction(error: String)
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "The requested product could not be found."
        case .failedVerification:
            return "Transaction verification failed."
        case .userCancelled:
            return "The purchase was cancelled by the user."
        case .pending:
            return "The purchase is pending approval."
        case .failedTransaction(let error):
            return "The transaction failed: \(error)"
        case .unknown:
            return "An unknown error occurred."
        }
    }
} 