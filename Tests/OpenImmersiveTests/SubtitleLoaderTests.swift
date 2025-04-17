//
//  SubtitleLoaderTests.swift
//  OpenImmersive
//
//  Created by Linxuan Lu on 9/4/25.
//

import XCTest
@testable import OpenImmersive

final class SubtitleLoaderTests: XCTestCase {

    func testLoadSRT() {
        let srtContent = """
        1
        00:00:01,000 --> 00:00:03,000
        Hello world!

        2
        00:00:04,000 --> 00:00:06,000
        This is a subtitle test.
        """

        let entries = SubtitleLoader.parseSRT(srtContent)
        XCTAssertEqual(entries.count, 2)
        XCTAssertEqual(entries[0].text, "Hello world!")
        XCTAssertEqual(entries[1].startTime, 4.0, accuracy: 0.01)
    }
    
    func testLoadMultiLineSRT() {
        let srtContent = """
        1
        00:00:01,000 --> 00:00:03,000
        Hello world!
        123

        2
        00:00:04,000 --> 00:00:06,000
        This is a subtitle test.
        321
        """

        let entries = SubtitleLoader.parseSRT(srtContent)
        XCTAssertEqual(entries.count, 2)
        XCTAssertEqual(entries[0].text, "Hello world!\n123")
        XCTAssertEqual(entries[1].startTime, 4.0, accuracy: 0.01)
        XCTAssertEqual(entries[1].text, "This is a subtitle test.\n321")
    }

    func testLoadVTT() {
        let vttContent = """
        WEBVTT

        00:00:01.000 --> 00:00:03.000
        Hello from VTT!

        00:00:04.000 --> 00:00:06.000
        Another subtitle entry.
        """

        let entries = SubtitleLoader.parseVTT(vttContent)
        XCTAssertEqual(entries.count, 2)
        XCTAssertEqual(entries[0].text, "Hello from VTT!")
        XCTAssertEqual(entries[1].endTime, 6.0, accuracy: 0.01)
    }

    func testLoadMultiLineVTT() {
        let vttContent = """
        WEBVTT

        1
        00:00:01.000 --> 00:00:03.000
        Hello from VTT!
        123

        2
        00:00:04.000 --> 00:00:06.000
        Another subtitle entry.
        321
        """

        let entries = SubtitleLoader.parseVTT(vttContent)
        XCTAssertEqual(entries.count, 2)
        XCTAssertEqual(entries[0].text, "Hello from VTT!\n123")
        XCTAssertEqual(entries[1].endTime, 6.0, accuracy: 0.01)
        XCTAssertEqual(entries[1].text, "Another subtitle entry.\n321")
    }
    
    func testInvalidFormat() {
        let brokenSRT = """
        1
        00:00:01,000 - 00:00:03,000
        Missing arrow.
        """

        let entries = SubtitleLoader.parseSRT(brokenSRT)
        XCTAssertEqual(entries.count, 0)
    }
}
