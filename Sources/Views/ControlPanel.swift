//
//  ControlPanel.swift
//  OpenImmersive
//
//  Created by Anthony Maës (Acute Immersive) on 9/20/24.
//

import SwiftUI
import RealityKit

/// A simple horizontal view presenting the user with video playback controls.
public struct ControlPanel: View {
    /// The singleton video player control interface.
    @Binding var videoPlayer: VideoPlayer
    @State var isShowingSubtitleSection: Bool = true
    @State var previewImage: Image? = nil
    /// The callback to execute when the user closes the immersive player.
    let closeAction: (() -> Void)?
    
    /// Public initializer for visibility.
    /// - Parameters:
    ///   - videoPlayer: the singleton video player control interface.
    ///   - closeAction: the optional callback to execute when the user closes the immersive player.
    public init(videoPlayer: Binding<VideoPlayer>, closeAction: (() -> Void)? = nil) {
        self._videoPlayer = videoPlayer
        self.closeAction = closeAction
    }
    
    public var body: some View {
        if videoPlayer.shouldShowControlPanel {
            VStack {
                HStack {
                    if let img = self.previewImage {
                        img.resizable()
                            .scaledToFit()
                            .frame(width: 400, height: 400)
                            .cornerRadius(16)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(radius: 16)
                    }
                }.frame(width: 400, height: 400)
                
                VStack {
                    HStack(spacing: 24) {
                        Button("", systemImage: "chevron.backward") {
                            closeAction?()
                        }
                        .controlSize(.extraLarge)
                        .tint(.clear)
                        
                        MediaInfo(videoPlayer: $videoPlayer)
                        
                        Button {
                            videoPlayer.toggleSubtitles()
                        } label: {
                            VStack {
                                Image(systemName: "captions.bubble")
                                    .font(.system(size: 36))
                                    .foregroundColor(videoPlayer.shouldShowSubtitles ? .blue : .gray)
                                
                                Text("Subtitle")
                            }
                        }.buttonStyle(.plain)
                        
                        Button {
                            videoPlayer.toggleBullets()
                        } label: {
                            VStack {
                                Image(systemName: "list.bullet.rectangle")
                                    .font(.system(size: 36))
                                    .foregroundColor(videoPlayer.shouldShowBullets ? .blue : .gray)
                                
                                Text("Bullets")
                            }
                        }.buttonStyle(.plain)
                    }.padding(.horizontal)
                    
                    if videoPlayer.shouldShowSubtitles {
                        SubtitleButtons(videoPlayer: videoPlayer)
                            .animation(.easeInOut(duration: 0.2), value: videoPlayer.shouldShowSubtitles)
                    }
                    
                    HStack {
                        PlaybackButtons(videoPlayer: videoPlayer)
                        
                        Scrubber(videoPlayer: $videoPlayer)
                        
                        TimeText(videoPlayer: videoPlayer)
                    }
                    
                    if videoPlayer.shouldShowBullets {
                        BulletView(videoPlayer: videoPlayer)
                            .animation(.easeInOut(duration: 0.2), value: videoPlayer.shouldShowBullets)
                    }
                }
                .padding()
                .glassBackgroundEffect()
            }
            .onChange(of: self.videoPlayer.previewImage) { oldValue, newValue in
                self.previewImage = newValue
            }
        }
    }
}

/// A simple horizontal view with a dark background presenting video title, description, and a bitrate readout.
fileprivate struct MediaInfo: View {
    /// The singleton video player control interface.
    @Binding var videoPlayer: VideoPlayer
    
    var body: some View {
        let config = Config.shared
        
        HStack {
            let hasResolutionOptions = videoPlayer.resolutionOptions.count > 1  && config.controlPanelShowResolutionOptions
            let showingResolutionOptions = hasResolutionOptions && videoPlayer.shouldShowResolutionOptions
            let showingBitrate = videoPlayer.bitrate > 0 && !showingResolutionOptions && config.controlPanelShowBitrate
            
            if !showingResolutionOptions {
                // extra padding to keep the stack centered when the bitrate is visible
                let extraPadding: () -> CGFloat = {
                    var padding: CGFloat = 0
                    if showingBitrate {
                        padding += 120
                    }
                    if hasResolutionOptions {
                        padding += 100
                    }
                    if showingBitrate && hasResolutionOptions {
                        padding += 10
                    }
                    return padding
                }
                
                Spacer()
                VStack {
                    Text(videoPlayer.title.isEmpty ? "No Video Selected" : videoPlayer.title)
                        .font(.title)
                    
                    Text(videoPlayer.details)
                        .font(.headline)
                }
                .padding(.leading, extraPadding())
                Spacer()

                if showingBitrate {
                    Text("\(videoPlayer.bitrate/1_000_000, specifier: "%.1f") Mbps")
                        .frame(width: 120)
                        .monospacedDigit()
                        .foregroundStyle(color(for: videoPlayer.bitrate, ladder: videoPlayer.resolutionOptions).opacity(0.8))
                }
            }
            
            if hasResolutionOptions {
                ResolutionSelector(videoPlayer: $videoPlayer)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 60, alignment: .center)
        .padding()
        .background(Color.black.opacity(0.5))
        .cornerRadius(20)
    }
    
    /// Evaluates the font color for the bitrate label depending on bitrate value.
    /// - Parameters:
    ///   - bitrate: the bitrate value as an `Double`
    ///   - ladder: the resolution options for the stream
    ///   - tolerance: the tolerance for color threshold (default 1.2Mbps)
    /// - Returns: White if top bitrate for the stream, yellow if second best, orange if third best, red otherwise.
    private func color(for bitrate: Double, ladder options: [ResolutionOption], tolerance: Int = 1_200_000) -> Color {
        if options.count > 3 && bitrate < Double(options[2].bitrate - tolerance) {
            .red
        } else if options.count > 2 && bitrate < Double(options[1].bitrate - tolerance) {
            .orange
        } else if options.count > 1 && bitrate < Double(options[0].bitrate - tolerance) {
            .yellow
        } else {
            .white
        }
    }
}

fileprivate struct ResolutionSelector: View {
    @Binding var videoPlayer: VideoPlayer
    
    var body: some View {
        HStack {
            if videoPlayer.shouldShowResolutionOptions {
                Spacer()
                
                Button {
                    videoPlayer.openResolutionOption(index: -1)
                } label: {
                    Text("Auto")
                        .font(.headline)
                }
                
                let options = videoPlayer.resolutionOptions
                let zippedOptions = Array(zip(options.indices, options))
                ForEach(zippedOptions, id: \.0) { index, option in
                    Button {
                        videoPlayer.openResolutionOption(index: index)
                    } label: {
                        Text(option.resolutionString)
                            .font(.subheadline)
                        Text(option.bitrateString)
                            .font(.caption)
                    }
                }
            }
            
            Button("", systemImage: "gearshape.fill") {
                videoPlayer.toggleResolutionOptions()
            }
            .frame(width: 100)
        }
    }
}


/// A simple horizontal view presenting the user with video playback control buttons.
fileprivate struct PlaybackButtons: View {
    var videoPlayer: VideoPlayer
    
    var body: some View {
        HStack {
            Button("", systemImage: "gobackward.15") {
                videoPlayer.minus15()
            }
            .controlSize(.extraLarge)
            .tint(.clear)
            .frame(width: 100)
            
            if videoPlayer.paused {
                Button("", systemImage: "play") {
                    videoPlayer.play()
                }
                .controlSize(.extraLarge)
                .tint(.clear)
                .frame(width: 100)
            } else {
                Button("", systemImage: "pause") {
                    videoPlayer.pause()
                }
                .controlSize(.extraLarge)
                .tint(.clear)
                .frame(width: 100)
            }
            
            Button("", systemImage: "goforward.15") {
                videoPlayer.plus15()
            }
            .controlSize(.extraLarge)
            .tint(.clear)
            .frame(width: 100)
        }
    }
}

fileprivate struct BulletView: View {
    @State var bullet = ""
    @FocusState private var isFocused: Bool

    var videoPlayer: VideoPlayer
    
    var body: some View {
        HStack(alignment: .top) {
            TextEditor(text: $bullet)
                .padding(8)
                .font(.system(size: 30))
                .frame(height: isFocused ? 120 : 50)
                .focused($isFocused)
                .foregroundColor(.white)
                .background(
                    ZStack {
                        Color(.systemGray).opacity(0.7)
                        
                        if bullet.isEmpty {
                            Text("Say something...")
                                .foregroundColor(.white)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                                .transition(.opacity)
                        }
                    }.cornerRadius(10)
                        .shadow(radius: 12)
                )
                .animation(.easeInOut, value: isFocused)
                .onChange(of: self.isFocused) { oldValue, newValue in
                    if newValue {
                        self.videoPlayer.cancelControlPanelTask()
                    } else {
                        self.videoPlayer.restartControlPanelTask()
                    }
                }
            
            if self.isFocused {
                Button {
                    self.videoPlayer.sendBulletAction?(self.bullet, self.videoPlayer.currentTime)
                    self.videoPlayer.currentBullets.append(self.bullet)
                    self.bullet = ""
                    self.isFocused = false
                } label: {
                    Label("Send", systemImage: "bubble")
                        .padding()
                        .foregroundColor(.green)
                        .background(RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.green, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                        )
                        .contentShape(RoundedRectangle(cornerRadius: 16))
                }.buttonStyle(.plain)
                    .animation(.easeInOut, value: bullet)
                    .frame(width: 140, height: 60)
                    .disabled(bullet.isEmpty)
            }
        }
    }
}

/// Control subtitles
fileprivate struct SubtitleButtons: View {
    @State var subtitleColor = Color.white
    @State var language = ""

    var videoPlayer: VideoPlayer
    
    var body: some View {
        HStack {
            Button("", systemImage: "minus.circle") {
                videoPlayer.minusFont()
            }
            .controlSize(.extraLarge)
            .tint(.clear)
            .frame(width: 100)
            
            Text("\(Int(videoPlayer.subtitleFontSize))")
                .font(.system(size: videoPlayer.subtitleFontSize))
                        
            Button("", systemImage: "plus.circle") {
                videoPlayer.plusFont()
            }
            .controlSize(.extraLarge)
            .tint(.clear)
            .frame(width: 100)
            
            Picker("", selection: $subtitleColor) {
                Text("White").tag(Color.white)
                Text("Yellow").tag(Color.yellow)
                Text("Green").tag(Color.green)
                Text("Red").tag(Color.red)
                Text("Blue").tag(Color.blue)
            }
            .pickerStyle(.segmented)
            .onChange(of: subtitleColor) { oldValue, newValue in
                videoPlayer.changeSubtitleColor(newValue)
            }
            
            if videoPlayer.availableLanguages().count > 1 {
                Picker("", selection: $language) {
                    ForEach(videoPlayer.availableLanguages(), id: \.self) { l in
                        Text(l).tag(l)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: language) { oldValue, newValue in
                    videoPlayer.changeLanguage(newValue)
                }
            }
        }.onAppear() {
            self.language = videoPlayer.currentSubtitlesLanguage
            self.subtitleColor = videoPlayer.subtitleColor
        }
    }
}

/// A video scrubber made of a slider, which uses a simple state machine contained in `videoPlayer`.
/// Allows users to set the video to a specific time, while otherwise reflecting the current position in playback.
fileprivate struct Scrubber: View {
    @Binding var videoPlayer: VideoPlayer
    let config = Config.shared
    
    var body: some View {
        Slider(value: $videoPlayer.currentTime, in: 0...videoPlayer.duration) { scrubbing in
            if scrubbing {
                videoPlayer.scrubState = .scrubStarted
            } else {
                videoPlayer.scrubState = .scrubEnded
            }
        }
        .controlSize(.extraLarge)
        .tint(config.controlPanelScrubberTint)
        .background(Color.white.opacity(0.5), in: .capsule)
        .padding()
    }
}

/// A label view printing the current time and total duration of a video.
fileprivate struct TimeText: View {
    var videoPlayer: VideoPlayer
    
    var body: some View {
        Text(timeString)
            .font(.headline)
            .monospacedDigit()
            .frame(width: frameWidth)
    }
    
    var timeString: String {
        guard videoPlayer.duration > 0 else {
            return "--:-- / --:--"
        }
        let timeFormat: Duration.TimeFormatStyle = videoPlayer.duration >= 3600 ? .time(pattern: .hourMinuteSecond) : .time(pattern: .minuteSecond)
        
        let currentTime = Duration
            .seconds(videoPlayer.currentTime)
            .formatted(timeFormat)
        let duration = Duration
            .seconds(videoPlayer.duration)
            .formatted(timeFormat)
        
        return "\(currentTime) / \(duration)"
    }
    
    var frameWidth: CGFloat {
        get {
            if videoPlayer.duration >= 36_000 {
                return 200
            }
            if videoPlayer.duration >= 3600 {
                return 180
            }
            return 150
        }
    }
}

//#Preview(windowStyle: .automatic, traits: .fixedLayout(width: 1200, height: 45)) {
//    ControlPanel(videoPlayer: .constant(VideoPlayer()))
//}

#Preview {
    RealityView { content, attachments in
        if let entity = attachments.entity(for: "ControlPanel") {
            content.add(entity)
        }
    } attachments: {
        Attachment(id: "ControlPanel") {
            ControlPanel(videoPlayer: .constant(VideoPlayer()))
        }
    }
}
