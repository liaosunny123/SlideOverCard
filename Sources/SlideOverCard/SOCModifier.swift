import SwiftUI
import Combine

@available(iOS 14.0, *)
internal struct SOCModifier<ViewContent: View, Style: ShapeStyle>: ViewModifier {
    var model: SOCModel
    @Binding var isPresented: Bool
    
    private let manager: SOCManager<ViewContent, Style>
    
    @Environment(\.colorScheme) var colorScheme
    
    init(isPresented: Binding<Bool>,
                onDismiss: (() -> Void)? = nil,
                options: SOCOptions,
                style: SOCStyle<Style>,
                @ViewBuilder content: @escaping () -> ViewContent) {
        let model = SOCModel()
        self.model = model
        self._isPresented = isPresented
        
        self.manager = .init(model: model,
                             onDismiss: onDismiss,
                             options: options,
                             style: style,
                             content: content)
        
        self.model.showCard = isPresented.wrappedValue
    }
    
    func body(content: Content) -> some View {
        content
            .onReceive(Just(colorScheme)) { value in
                manager.set(colorScheme: value)
            }
            .onReceive(model.$showCard.receive(on: RunLoop.main)) { value in
                if value != isPresented {
                    isPresented = value
                }
            }
            .onReceive(Just(isPresented)) { value in
                if value {
                    manager.present()
                } else {
                    manager.dismiss()
                }
            }
            .onChange(of: isPresented) { value in
                if value != model.showCard {
                    model.showCard = value
                }
            }
            .background(windowAccessor)
    }
    
    var windowAccessor: some View {
        WindowAccessor { window in
            manager.set(window: window)
        }
        .allowsHitTesting(false)
    }
}
