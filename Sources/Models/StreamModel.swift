//
//  StreamModel.swift
//  OpenImmersive
//
//  Created by Anthony Maës (Acute Immersive) on 9/25/24.
//

import Foundation

public struct BulletEntry: Codable {
    let time: TimeInterval
    let text: String
}

/// Simple structure describing a video stream.
public struct StreamModel: Codable {
    /// The title of the video stream.
    public var title: String
    /// A short description of the video stream.
    public var details: String
    /// URL to a media, whether local or streamed from a HLS server (m3u8).
    public var url: URL
    /// The fallback horizontal field of view angle of the video stream (if cannot be determined from the media).
    public var fallbackFieldOfView: Float
    /// Setting this to a non-nil value will force the horizontal field of view angle of the stream to the corresponding value (overriding the value that's encoded in the media).
    public var forceFieldOfView: Float?
    /// True if the media required user permission for access.
    public var isSecurityScoped: Bool
    /// Dicttionary of language label to subtitle
    public let languageToSubtitleFiles: [SubtitleFileType: [String: URL]]?
    
    public var videoBullets: [BulletEntry]
    public var videoId: Int

    /// Public initializer for visibility.
    /// - Parameters:
    ///   - title: the title of the video stream.
    ///   - details: a short description of the video stream.
    ///   - url: URL to a media, whether local or streamed from a server (m3u8).
    ///   - fallbackFieldOfView: the fallback horizontal field of view of the video, if cannot be determined from the media, in degrees (default 180.0).
    ///   - forceFieldOfView: optional forced horizontal field of view of the video, if needed to override the value encoded in the media, in degrees (default nil).
    ///   - isSecurityScoped: true if the media required user permission for access (default false).
    ///   - languageToSubtitleFiles: a dict of language label -> subtitle URL

    public init(title: String, details: String, videoId: Int, url: URL, fallbackFieldOfView: Float = 180.0, forceFieldOfView: Float? = nil, isSecurityScoped: Bool = false, languageToSubtitleFiles: [SubtitleFileType: [String: URL]]? = nil, videoBullets: [BulletEntry] = []) {
        precondition(languageToSubtitleFiles == nil || languageToSubtitleFiles?.count == 1, "Only one type of subtitle file can be provided.")
        self.title = title
        self.details = details
        self.url = url
        self.fallbackFieldOfView = fallbackFieldOfView
        self.forceFieldOfView = forceFieldOfView
        self.isSecurityScoped = isSecurityScoped
        self.languageToSubtitleFiles = languageToSubtitleFiles
        self.videoBullets = videoBullets
        self.videoId = videoId
    }
}

extension StreamModel: Identifiable {
    public var id: String { url.absoluteString }
}

extension StreamModel: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension StreamModel: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

public enum SubtitleFileType: Codable {
    case SRT
    case VTT
    case HLS
}
