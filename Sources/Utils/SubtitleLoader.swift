//
//  SubtitleLoader.swift
//  OpenImmersive
//
//  Created by Linxuan Lu on 9/4/25.
//

import Foundation

struct SubtitleEntry {
    let startTime: TimeInterval
    let endTime: TimeInterval
    let text: String
}

enum SubtitleFormat {
    case srt
    case vtt
}

class SubtitleLoader {
    
    static func load(from url: URL, format: SubtitleFormat, completion: @escaping @Sendable ([SubtitleEntry]) -> Void) {
        if url.isFileURL {
            // local file
            if let content = try? String(contentsOf: url, encoding: .utf8) {
                let result = format == .srt ? parseSRT(content) : parseVTT(content)
                completion(result)
            } else {
                print("Failed to read local subtitle file")
                completion([])
            }
        } else {
            // remote file
            let task = URLSession.shared.dataTask(with: url) { data, response, error in
                guard let data = data, let content = String(data: data, encoding: .utf8) else {
                    print("Failed to download subtitle from \(url)")
                    completion([])
                    return
                }
                let result = format == .srt ? parseSRT(content) : parseVTT(content)
                completion(result)
            }
            task.resume()
        }
    }
    
    internal static func parseSRT(_ content: String) -> [SubtitleEntry] {
        let blocks = content.components(separatedBy: "\n\n")
        var entries: [SubtitleEntry] = []

        for block in blocks {
            let lines = block.components(separatedBy: .newlines).filter { !$0.isEmpty }
            guard lines.count >= 3 else { continue }

            let timeLine = lines[1]
            let timeComponents = timeLine.components(separatedBy: " --> ")
            guard timeComponents.count == 2,
                  let start = parseTime(timeComponents[0]),
                  let end = parseTime(timeComponents[1]) else {
                continue
            }

            let text = lines[2...].joined(separator: "\n")
            entries.append(SubtitleEntry(startTime: start, endTime: end, text: text))
        }

        return entries
    }

    internal static func parseVTT(_ content: String) -> [SubtitleEntry] {
        let lines = content.components(separatedBy: "\n")
        var entries: [SubtitleEntry] = []
        var index = 0

        while index < lines.count {
            if lines[index].contains("-->") {
                let timeComponents = lines[index].components(separatedBy: " --> ")
                guard timeComponents.count == 2,
                      let start = parseTime(timeComponents[0]),
                      let end = parseTime(timeComponents[1]) else {
                    index += 1
                    continue
                }

                var textLines: [String] = []
                index += 1
                while index < lines.count && !lines[index].isEmpty {
                    textLines.append(lines[index])
                    index += 1
                }

                let text = textLines.joined(separator: "\n")
                entries.append(SubtitleEntry(startTime: start, endTime: end, text: text))
            }
            index += 1
        }

        return entries
    }

    private static func parseTime(_ timeString: String) -> TimeInterval? {
        let cleaned = timeString.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespaces)
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        if let date = formatter.date(from: cleaned) {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.hour, .minute, .second, .nanosecond], from: date)
            let secondPart = (components.hour ?? 0) * 3600 + (components.minute ?? 0) * 60 + (components.second ?? 0)
            let seconds = Double(secondPart) + Double(components.nanosecond ?? 0) / 1_000_000_000
            return seconds
        }
        return nil
    }
}
