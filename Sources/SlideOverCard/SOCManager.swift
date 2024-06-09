import SwiftUI
import Combine

/// A manager class that presents a `SlideOverCard`overlay from anywhere in an app
internal class SOCManager<Content: View, Style: ShapeStyle>: ObservableObject {
    @ObservedObject var model: SOCModel
    
    var cardController: UIHostingController<SlideOverCard<Content, Style>>?
    
    var onDismiss: (() -> Void)?
    var content: () -> Content
    var window: UIWindow?
    
    private var cancellables = Set<AnyCancellable>()
    
    init(model: SOCModel,
         onDismiss: (() -> Void)?,
         options: SOCOptions,
         style: SOCStyle<Style>,
         @ViewBuilder content: @escaping () -> Content) {
        self.onDismiss = onDismiss
        self.content = content
        
        self.model = model
        let rootCard = SlideOverCard(model: _model,
                                     options: options,
                                     style: style,
                                     content: content)
        
        cardController = UIHostingController(rootView: rootCard)
        cardController?.view.backgroundColor = .clear
        cardController?.modalPresentationStyle = .overFullScreen
        
        model.$showCard
            .removeDuplicates()
            .sink { [weak self] value in
                if !value {
                    self?.dismiss()
                }
            }
            .store(in: &cancellables)
    }
    
    /// Presents a `SlideOverCard`
    @available(iOSApplicationExtension, unavailable)
    func present() {
        if let cardController, !self.model.showCard {
            var topViewController = window?.topViewController()
            
            // Fallback
            if topViewController == nil {
                let windowScene = UIApplication.shared
                    .connectedScenes
                    .filter { $0.activationState == .foregroundActive }
                    .compactMap { $0 as? UIWindowScene }
                    .first
                
                topViewController = windowScene?
                    .windows
                    .filter { $0.isKeyWindow }
                    .first?
                    .rootViewController
            }
            
            if let topViewController {
                topViewController.present(cardController, animated: false) {
                    self.model.showCard = true
                }
            }
        }
    }
    
    /// Dismisses a `SlideOverCard`
    @available(iOSApplicationExtension, unavailable)
    func dismiss() {
        if self.model.showCard {
            onDismiss?()
            self.model.showCard = false
            DispatchQueue.main.asyncAfter(deadline: .now()+0.5) { [weak self] in
                self?.cardController?.dismiss(animated: false)
            }
        }
    }
    
    func set(colorScheme: ColorScheme) {
        cardController?.overrideUserInterfaceStyle = colorScheme.uiKit
    }
    
    func set(window: UIWindow) {
        self.window = window
    }
}
