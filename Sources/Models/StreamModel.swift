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
    public enum Projection: Codable {
        /// Spherical projection of an equirectangular (or half equirectangular) frame. Use this for mono or MV-HEVC stereo VR180 & VR360 video.
        /// - Parameters:
        ///   - fieldOfView: the horizontal field of view of the video, in degrees.
        ///   - force: if false, use the field of view encoded in the media (only for local MV-HEVC). If true, use the provided `fieldOfView` no matter what (default false).
        case equirectangular(fieldOfView: Float, force: Bool = false)
        /// Rectangular video. Use this for 2D video and Spatial Video.
        case rectangular
        /// Native rendering for Apple Immersive Video (AIVU).
        case appleImmersive
    }
    
    /// The title of the video stream.
    public var title: String
    /// A short description of the video stream.
    public var details: String
    /// URL to a media, whether local or streamed from a HLS server (m3u8).
    public var url: URL
    /// The projection type of the media.
    public var projection: Projection
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
    ///   - projection: the projection type of the media (default 180.0 degree equirectangular).
    ///   - isSecurityScoped: true if the media required user permission for access (default false).
    ///   - languageToSubtitleFiles: a dict of language label -> subtitle URL
    public init(title: String, details: String, videoId: Int, url: URL, projection: Projection = .equirectangular(fieldOfView: 180.0), isSecurityScoped: Bool = false, languageToSubtitleFiles: [SubtitleFileType: [String: URL]]? = nil, videoBullets: [BulletEntry] = []) {
        precondition(languageToSubtitleFiles == nil || languageToSubtitleFiles?.count == 1, "Only one type of subtitle file can be provided.")
        self.title = title
        self.details = details
        self.url = url
        self.projection = projection
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
