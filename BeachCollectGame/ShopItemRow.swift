import SwiftUI

/// Displays a purchasable item with its icon and price.
struct ShopItemRow: View {
    let item: ShopItem
    var owned: Bool = false
    var disabled: Bool = false
    /// When the item is locked due to insufficient friend points,
    /// ``requiredFP`` represents the friend point threshold needed to unlock it.
    var requiredFP: Int? = nil
    /// Currency icon image name used for price display. Defaults to gold.
    var currencyImageName: String = "Gold"
    var onPurchase: () -> Void = {}

    private var currencyIcon: some View {
        Image(currencyImageName)
            .resizable()
            .frame(width: 16, height: 16)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(item.imageName)
                .resizable()
                .frame(width: 60, height: 60)
                .grayscale(owned || disabled ? 1 : 0)
                .overlay(alignment: .topTrailing) {
                    if owned {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.indigo)
                            .padding(4)
                            .background(Color.white)
                            .clipShape(Circle())
                            .offset(x: 5, y: -5)
                    }
                }
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                if item.discount > 0 {
                    HStack(spacing: 4) {
                        Text("\(item.price + item.discount)")
                            .font(.caption2)
                            .strikethrough()
                        Text("\(item.price)")
                            .font(.caption)
                        Text("(-\(item.discount))")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                    }
                } else {
                    HStack(spacing: 4) {
                        currencyIcon
                        Text("\(item.price)")
                            .font(.caption)
                    }
                }
                if let requiredFP = requiredFP, disabled, !owned {
                    HStack(spacing: 4) {
                        Image("HeartIconTapped")
                            .resizable()
                            .frame(width: 16, height: 16)
                        Text("\(requiredFP)で開放")
                            .font(.caption2)
                    }
                }
            }
            .foregroundColor(.white)
            Spacer()
            if owned {
                Label("購入済み", systemImage: "checkmark.circle")
                    .fontWeight(.bold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.3))
                    .cornerRadius(8)
                    .foregroundColor(.white)
            } else {
                Button(action: onPurchase) {
                    Text("購入する")
                        .fontWeight(.bold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(disabled ? 0.1 : 0.3))
                        .cornerRadius(8)
                        .foregroundColor(disabled ? .gray : .white)
                }
                .disabled(disabled)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
