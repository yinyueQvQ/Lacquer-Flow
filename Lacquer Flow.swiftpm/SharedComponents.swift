import SwiftUI

// MARK: - Shared Components

struct LFButton: View {
    let title: String
    let action: () -> Void
    var style: LFButtonStyle = .primary
    @Environment(\.horizontalSizeClass) private var hSizeClass

    enum LFButtonStyle { case primary, secondary, accent }

    private var isIPad: Bool { hSizeClass == .regular }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: isIPad ? 18 : 15, weight: .regular, design: .serif))
                .foregroundColor(style == .secondary ? LFColors.brown : .white)
                .padding(.horizontal, isIPad ? 36 : 28)
                .padding(.vertical, isIPad ? 14 : 11)
                .background(buttonBackground)
                .clipShape(RoundedRectangle(cornerRadius: isIPad ? 13 : 10))
        }
    }

    @ViewBuilder
    private var buttonBackground: some View {
        switch style {
        case .primary:
            if let uiImg = UIImage(named: "Union1", in: .module, compatibleWith: nil) {
                Image(uiImage: uiImg).resizable().scaledToFill()
            } else {
                LFColors.brown
            }
        case .accent:
            if let uiImg = UIImage(named: "Union2", in: .module, compatibleWith: nil) {
                Image(uiImage: uiImg).resizable().scaledToFill()
            } else {
                LFColors.lightBrown
            }
        case .secondary:
            RoundedRectangle(cornerRadius: isIPad ? 13 : 10)
                .fill(LFColors.paper.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: isIPad ? 13 : 10)
                        .stroke(LFColors.brown.opacity(0.6), lineWidth: 1)
                )
        }
    }
}

struct PaperBackground: View {
    var body: some View {
        Group {
            if let uiImg = UIImage(named: "beijing", in: .module, compatibleWith: nil) {
                Image(uiImage: uiImg)
                    .resizable()
                    .scaledToFill()
            } else {
                Color(red: 0.961, green: 0.929, blue: 0.863)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
    }
}

// 1. 序章
struct IntroAnimationView: View {
    @ObservedObject var appState: AppState
    @State private var fanScale: CGFloat = 0.5
    @State private var fanOpacity: Double = 0
    @State private var fanRotation: Double = -12

    var body: some View {
        ZStack {
            Group {
                if let uiImg = UIImage(named: "launchbg", in: .module, compatibleWith: nil) {
                    Image(uiImage: uiImg).resizable().scaledToFill()
                } else {
                    Color(red: 0.18, green: 0.12, blue: 0.08)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()

            if let img = UIImage(named: "fan", in: .module, compatibleWith: nil) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 180, height: 180)
                    .padding(.bottom, 75)
                    .padding(.leading,20)
                    .scaleEffect(fanScale)
                    .opacity(fanOpacity)
                    .rotationEffect(.degrees(fanRotation))
            }
        }
        .onAppear {
            withAnimation(.spring(response: 1.3, dampingFraction: 0.65).delay(0.15)) {
                fanScale = 1.0
                fanOpacity = 1.0
                fanRotation = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.easeInOut(duration: 0.6)) {
                    appState.currentPhase = .tutorial
                }
            }
        }
    }
}
