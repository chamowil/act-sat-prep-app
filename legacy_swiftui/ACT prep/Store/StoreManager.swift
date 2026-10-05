//
//  StoreManager.swift
//  ACT prep
//

import Foundation
import StoreKit
import Observation

@Observable
final class StoreManager {
    static let shared = StoreManager()

    static let monthlyID = "actprep.pro.monthly"
    static let yearlyID = "actprep.pro.yearly"
    static let allProductIDs = [monthlyID, yearlyID]
    static let subscriptionGroupID = "ACTPrepPro"

    /// Practice questions available per subject before subscribing.
    static let freePracticeLimit = 10
    /// Tutorials available per subject before subscribing.
    static let freeTutorialLimit = 2
    /// Mock exams available before subscribing (exam 1 only).
    static let freeExamCount = 1

    private(set) var products: [Product] = []
    private(set) var isPro = false
    private(set) var isLoading = false
    /// True until the first entitlement check finishes, so the UI does not
    /// flash locked content for an existing subscriber at launch.
    private(set) var hasResolvedEntitlements = false
    var purchaseError: String?

    private var updatesTask: Task<Void, Never>?

    private init() {
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                if let transaction = try? update.payloadValue {
                    await transaction.finish()
                    await self?.refreshEntitlements()
                }
            }
        }
        Task {
            await loadProducts()
            await refreshEntitlements()
        }
    }

    var monthly: Product? { products.first { $0.id == Self.monthlyID } }
    var yearly: Product? { products.first { $0.id == Self.yearlyID } }

    @MainActor
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let loaded = try await Product.products(for: Self.allProductIDs)
            products = loaded.sorted { $0.price < $1.price }
            purchaseError = nil
        } catch {
            purchaseError = "Could not load subscription options. Check your connection and try again."
        }
    }

    @MainActor
    func refreshEntitlements() async {
        var pro = false
        for await entitlement in Transaction.currentEntitlements {
            if let transaction = try? entitlement.payloadValue,
               Self.allProductIDs.contains(transaction.productID),
               transaction.revocationDate == nil {
                pro = true
            }
        }
        isPro = pro
        hasResolvedEntitlements = true
    }

    @MainActor
    func purchase(_ product: Product) async {
        purchaseError = nil
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try verification.payloadValue
                await transaction.finish()
                await refreshEntitlements()
            case .userCancelled:
                break
            case .pending:
                purchaseError = "Your purchase is pending approval."
            @unknown default:
                break
            }
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    @MainActor
    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            if !isPro {
                purchaseError = "No active subscription was found for this Apple Account."
            }
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    /// Percentage saved by the yearly plan versus paying monthly for a year.
    var yearlySavingsPercent: Int? {
        guard let monthly, let yearly else { return nil }
        let yearOfMonthly = monthly.price * 12
        guard yearOfMonthly > 0 else { return nil }
        let savings = (yearOfMonthly - yearly.price) / yearOfMonthly * 100
        let percent = Int(NSDecimalNumber(decimal: savings).doubleValue.rounded())
        return percent > 0 ? percent : nil
    }

    // MARK: Gating

    func isExamUnlocked(_ exam: MockExam) -> Bool {
        isPro || exam.index < Self.freeExamCount
    }

    func isPracticeQuestionUnlocked(index: Int) -> Bool {
        isPro || index < Self.freePracticeLimit
    }

    func isTutorialUnlocked(_ tutorial: Tutorial) -> Bool {
        guard !isPro else { return true }
        let siblings = TutorialLibrary.shared.tutorials(for: tutorial.subject)
        guard let index = siblings.firstIndex(where: { $0.id == tutorial.id }) else { return false }
        return index < Self.freeTutorialLimit
    }
}
