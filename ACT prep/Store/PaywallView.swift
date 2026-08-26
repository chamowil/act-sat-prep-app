//
//  PaywallView.swift
//  ACT prep
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var store = StoreManager.shared
    @State private var selectedProductID: String?
    @State private var isPurchasing = false

    private let privacyURL = URL(string: "https://chamowil.github.io/act-prep-support/privacy.html")!
    private let termsURL = URL(string: "https://chamowil.github.io/act-prep-support/terms.html")!

    private var selectedProduct: Product? {
        store.products.first { $0.id == selectedProductID }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    header
                    featureList
                    productOptions
                    purchaseButton
                    footer
                }
                .padding()
                .readableWidth(560)
            }
            .background(Color.appGroupedBackground)
            .navigationTitle("ACT Prep Pro")
            #if !targetEnvironment(macCatalyst)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .task {
                if store.products.isEmpty { await store.loadProducts() }
                selectDefaultProduct()
            }
            .onChange(of: store.products) { _, _ in selectDefaultProduct() }
            .onChange(of: store.isPro) { _, isPro in
                if isPro { dismiss() }
            }
        }
    }

    private func selectDefaultProduct() {
        guard selectedProductID == nil else { return }
        selectedProductID = store.yearly?.id ?? store.products.first?.id
    }

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "graduationcap.fill")
                .font(.system(size: 56))
                .foregroundStyle(.tint)
                .symbolRenderingMode(.hierarchical)
                .accessibilityHidden(true)
            Text("Unlock Everything")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
            Text("Every question, tutorial, and mock exam — on iPhone, iPad, and Mac.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top)
    }

    private var featureList: some View {
        VStack(alignment: .leading, spacing: 14) {
            feature("books.vertical.fill", "All 520 practice questions with step-by-step explanations")
            feature("book.fill", "40 Math & Science tutorials with worked examples")
            feature("timer", "All 15 mock exams — Quick and Full-Length timing")
            feature("chart.line.uptrend.xyaxis", "Score history, streaks, and subject analytics")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .cardBackground()
    }

    private func feature(_ symbol: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .foregroundStyle(.tint)
                .frame(width: 28)
                .accessibilityHidden(true)
            Text(text)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var productOptions: some View {
        if store.products.isEmpty {
            VStack(spacing: 10) {
                if store.isLoading {
                    ProgressView().padding()
                } else {
                    Text(store.purchaseError ?? "Subscription options are unavailable right now.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Try Again") { Task { await store.loadProducts() } }
                        .font(.footnote.bold())
                }
            }
        } else {
            VStack(spacing: 10) {
                ForEach(store.products, id: \.id) { product in
                    productRow(product)
                }
            }
        }
    }

    private func productRow(_ product: Product) -> some View {
        let isSelected = selectedProductID == product.id
        let isYearly = product.id == StoreManager.yearlyID

        return Button {
            selectedProductID = product.id
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(planName(product))
                            .font(.headline)
                        if isYearly, let savings = store.yearlySavingsPercent {
                            TagPill(text: "Save \(savings)%", tint: .green)
                        }
                    }
                    Text(subtitle(for: product))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(product.displayPrice)
                        .font(.headline)
                    Text(periodLabel(product))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .cardBackground(cornerRadius: 14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.accentColor : .clear, lineWidth: 2)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private func planName(_ product: Product) -> String {
        product.id == StoreManager.yearlyID ? "Yearly" : "Monthly"
    }

    private func periodLabel(_ product: Product) -> String {
        product.id == StoreManager.yearlyID ? "per year" : "per month"
    }

    private func subtitle(for product: Product) -> String {
        if product.id == StoreManager.yearlyID {
            if let offer = product.subscription?.introductoryOffer, offer.paymentMode == .freeTrial {
                return "Start with a free trial, then billed yearly."
            }
            return "Billed once a year. Cancel anytime."
        }
        return "Billed every month. Cancel anytime."
    }

    private var purchaseButton: some View {
        VStack(spacing: 8) {
            Button {
                guard let product = selectedProduct else { return }
                isPurchasing = true
                Task {
                    await store.purchase(product)
                    isPurchasing = false
                }
            } label: {
                Group {
                    if isPurchasing {
                        ProgressView().tint(.white)
                    } else {
                        Text(continueTitle)
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedProduct == nil || isPurchasing)

            if let error = store.purchaseError, !store.products.isEmpty {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var continueTitle: String {
        if let product = selectedProduct,
           let offer = product.subscription?.introductoryOffer,
           offer.paymentMode == .freeTrial {
            return "Start Free Trial"
        }
        return "Subscribe"
    }

    private var footer: some View {
        VStack(spacing: 10) {
            Button("Restore Purchases") {
                Task { await store.restorePurchases() }
            }
            .font(.footnote)

            Text("Payment is charged to your Apple Account at confirmation of purchase. Subscriptions renew automatically unless cancelled at least 24 hours before the end of the current period. Manage or cancel in Settings › Apple Account › Subscriptions.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 16) {
                Link("Privacy Policy", destination: privacyURL)
                Link("Terms of Use", destination: termsURL)
            }
            .font(.caption2)
        }
    }
}

#Preview {
    PaywallView()
}
