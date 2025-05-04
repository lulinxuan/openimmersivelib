//
//  ImmersivePlayer.swift
//  OpenImmersive
//
//  Created by Anthony Maës (Acute Immersive) on 9/11/24.
//

import SwiftUI
import RealityKit
import AVFoundation

/// An immersive video player, complete with UI controls
public struct ImmersivePlayer: View {
    /// The singleton video player control interface.
    @State var videoPlayer: VideoPlayer = VideoPlayer()
    
    /// The object managing the sphere or half-sphere displaying the video.
    // This needs to be a @State otherwise the video doesn't load.
    @State private(set) var videoScreen = VideoScreen()
    
    /// The stream for which the player was open.
    ///
    /// The current implementation assumes only one media per appearance of the ImmersivePlayer.
    let selectedStream: StreamModel
    
    /// The callback to execute when the user closes the immersive player.
    let closeAction: (() -> Void)?
    
    /// The pose tracker ensuring the position of the control panel attachment is fixed relatively to the viewer.
    private let headTracker = HeadTracker()
    
    /// Public initializer for visibility.
    /// - Parameters:
    ///   - selectedStream: the stream for which the player will be open.
    ///   - closeAction: the callback to execute when the user closes the immersive player.
    ///   - playbackEndedAction: the callback to execute when playback reaches the end of the video.
    public init(selectedStream: StreamModel, closeAction: (() -> Void)? = nil, playbackEndedAction: (() -> Void)? = nil, sendBulletAction: ((String, Double) -> Void)? = nil) {
        self.selectedStream = selectedStream
        self.closeAction = closeAction
        self.videoPlayer.playbackEndedAction = playbackEndedAction
        self.videoPlayer.sendBulletAction = sendBulletAction
    }
    
    public var body: some View {
        RealityView { content, attachments in
            let config = Config.shared
            let root = Entity()

            root.name = "Root"
            root.position = [0.0, 1.2, 0.0]
            
            // Setup root entity that will remain static relatively to the head
            content.add(root)
            headTracker.start(content: content) { _ in
                guard let headTransform = headTracker.transform else {
                    return
                }
                let headPosition = simd_make_float3(headTransform.columns.3)
                root.position = headPosition
            }
            
            // Setup video sphere/half sphere entity
            root.addChild(videoScreen.entity)
            
            // Setup ControlPanel as a floating window within the immersive scene
            if let controlPanel = attachments.entity(for: "ControlPanel") {
                controlPanel.name = "ControlPanel"
                controlPanel.position = [0, config.controlPanelVerticalOffset, -config.controlPanelHorizontalOffset]
                controlPanel.orientation = simd_quatf(angle: -config.controlPanelTilt * .pi/180, axis: [1, 0, 0])
                root.addChild(controlPanel)
            }
            
            // Show a spinny animation when the video is buffering
            if let progressView = attachments.entity(for: "ProgressView") {
                progressView.name = "ProgressView"
                progressView.position = [0, 0, -0.7]
                root.addChild(progressView)
            }
            
            // Setup an invisible object that will catch all taps behind the control panel
            let tapCatcher = makeTapCatcher()
            root.addChild(tapCatcher)
        } update: { content, attachments in
            if let progressView = attachments.entity(for: "ProgressView") {
                progressView.isEnabled = videoPlayer.buffering
            }
            if !self.videoPlayer.currentBullets.isEmpty {
                let bullet = self.videoPlayer.currentBullets.removeFirst()
                self.playBullet(text: bullet, content: content)
            }
        } placeholder: {
            ProgressView()
        } attachments: {
            Attachment(id: "ControlPanel") {
                VStack {
                    if let subtitle = videoPlayer.currentSubtitle, videoPlayer.shouldShowSubtitles && !subtitle.isEmpty {
                        Text(subtitle)
                            .padding()
                            .background(.black.opacity(0.6))
                            .foregroundColor(videoPlayer.subtitleColor)
                            .font(.system(size: videoPlayer.subtitleFontSize))
                            .cornerRadius(12)
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 60)
                            .transition(.opacity)
                            .animation(.easeInOut(duration: 0.2), value: videoPlayer.currentSubtitle)
                    }
                    
                    ControlPanel(videoPlayer: $videoPlayer, closeAction: closeAction)
                        .animation(.easeInOut(duration: 0.3), value: videoPlayer.shouldShowControlPanel)
                }
            }
            
            Attachment(id: "ProgressView") {
                ProgressView()
            }
        }
        .onAppear {
            videoPlayer.openStream(selectedStream)
            videoPlayer.showControlPanel()
            videoPlayer.play()
            
            videoScreen.update(source: videoPlayer)
        }
        .onDisappear {
            videoPlayer.stop()
            videoPlayer.hideControlPanel()
            headTracker.stop()
            if selectedStream.isSecurityScoped {
                selectedStream.url.stopAccessingSecurityScopedResource()
            }
        }
        .gesture(TapGesture()
            .targetedToAnyEntity()
            .onEnded { event in
                videoPlayer.toggleControlPanel()
            }
        )
    }
    
    /// Programmatically generates a tap catching entity in the shape of a large invisible box in front of the viewer.
    /// Taps captured by this invisible shape will toggle the control panel on and off.
    /// - Parameters:
    ///   - debug: if `true`, will make the box red for debug purposes (default false).
    /// - Returns: a new tap catcher entity.
    private func makeTapCatcher(debug: Bool = false) -> some Entity {
        let collisionShape: ShapeResource =
            .generateBox(width: 100, height: 100, depth: 1)
            .offsetBy(translation: [0.0, 0.0, -5.0])
        
        let entity = debug ?
        ModelEntity(
            mesh: MeshResource(shape: collisionShape),
            materials: [UnlitMaterial(color: .red)]
        ) : Entity()
        
        entity.name = "TapCatcher"
        entity.components.set(CollisionComponent(shapes: [collisionShape], mode: .trigger, filter: .default))
        entity.components.set(InputTargetComponent())
        
        return entity
    }
    
    @MainActor
    private func playBullet(text: String, content: RealityViewContent) {
        let text = VideoTools.createTextModel(text: text, color: .random)
        text.position = [Float.random(in: -2.4 ... -2.2), Float.random(in: -0.8...0.8) + 1.2, Float.random(in: -3 ... -2.4)]
        content.add(text)
        let move = FromToByAnimation<Transform>(
            name: "move",
            to: .init(scale:  text.scale, rotation: text.orientation, translation: SIMD3<Float>(text.position.x + 4.6, text.position.y, text.position.z)),
            duration: 10,
            timing: .cubicBezier(controlPoint1: SIMD2<Float>(0.1, 0.3), controlPoint2: SIMD2<Float>(0.9, 0.7)),
            bindTarget: .transform
        )
        let resource = try! AnimationResource.generate(with: move)
        text.playAnimation(resource, transitionDuration: 10, startsPaused: false)
        Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { _ in
            Task {@MainActor in
                text.removeFromParent()
            }
        }
    }
}
