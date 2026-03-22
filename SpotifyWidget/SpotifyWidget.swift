//
//  SpotifyWidget.swift
//  SpotifyWidget
//
//  Created by Niko Dima on 19/03/2026.
//

import WidgetKit
import SwiftUI

#if canImport(AppKit)
import AppKit
typealias PlatformImage = NSImage
#else
import UIKit
typealias PlatformImage = UIImage
#endif

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SpotifyEntry {
        SpotifyEntry(date: Date(), trackName: "Blinding Lights", artistName: "The Weeknd", coverData: nil, isPlaying: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (SpotifyEntry) -> ()) {
        let entry = SpotifyEntry(date: Date(), trackName: "Blinding Lights", artistName: "The Weeknd", coverData: nil, isPlaying: true)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        // We read from the shared App Group UserDefaults
        let defaults = UserDefaults(suiteName: "group.dynamic_island")
        
        let trackName = defaults?.string(forKey: "spotify_trackName") ?? "Not Playing"
        let artistName = defaults?.string(forKey: "spotify_artistName") ?? "No Artist"
        let isPlaying = defaults?.bool(forKey: "spotify_isPlaying") ?? false
        let coverData = defaults?.data(forKey: "spotify_coverData")
        
        let entry = SpotifyEntry(date: Date(), trackName: trackName, artistName: artistName, coverData: coverData, isPlaying: isPlaying)
        
        // Refresh every minute, though the main app will force reload on track change
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct SpotifyEntry: TimelineEntry {
    let date: Date
    let trackName: String
    let artistName: String
    let coverData: Data?
    let isPlaying: Bool
}

struct SpotifyWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        HStack(spacing: 12) {
            // Album Art
            if let data = entry.coverData, let pImage = PlatformImage(data: data) {
                #if canImport(AppKit)
                Image(nsImage: pImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 50, height: 50)
                    .cornerRadius(8)
                    .shadow(radius: 2)
                #else
                Image(uiImage: pImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 50, height: 50)
                    .cornerRadius(8)
                    .shadow(radius: 2)
                #endif
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 50)
                    .cornerRadius(8)
                    .overlay(
                        Image(systemName: "music.note")
                            .foregroundColor(.white)
                    )
            }
            
            // Track Info
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.trackName)
                    .font(.headline)
                    .fontWeight(.bold)
                    .lineLimit(1)
                    .foregroundColor(.white)
                    
                Text(entry.artistName)
                    .font(.subheadline)
                    .lineLimit(1)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Play/Pause Icon
            Image(systemName: entry.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                .resizable()
                .frame(width: 25, height: 25)
                .foregroundColor(.green)
        }
        .padding()
        .containerBackground(Color.black.gradient, for: .widget)
    }
}

struct SpotifyWidget: Widget {
    let kind: String = "SpotifyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            SpotifyWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Spotify Player")
        .description("Shows your currently playing track from the Dynamic Island.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
