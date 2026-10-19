import Foundation
import Combine

/// 一次专注记录。
struct FocusSession: Codable, Identifiable, Hashable {
    let id: UUID
    let finishedAt: Date
    /// 本次专注秒数。
    let duration: TimeInterval
    /// 是否完整走完（未中途放弃）。
    let completed: Bool

    init(id: UUID = UUID(), finishedAt: Date = Date(), duration: TimeInterval, completed: Bool) {
        self.id = id
        self.finishedAt = finishedAt
        self.duration = duration
        self.completed = completed
    }
}

/// 专注历史的 JSON 持久化，并提供今日 / 本周统计。
final class PersistenceManager: ObservableObject {
    static let shared = PersistenceManager()

    @Published private(set) var sessions: [FocusSession] = []

    private let fileURL: URL
    private let calendar = Calendar.current

    private init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let dir = base.appendingPathComponent("Chron", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.fileURL = dir.appendingPathComponent("chron_sessions.json")
        load()
    }

    func add(_ session: FocusSession) {
        sessions.append(session)
        save()
    }

    func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let decoded = try? decoder.decode([FocusSession].self, from: data) {
            sessions = decoded
        }
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(sessions) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    // MARK: - 统计

    func sessions(on date: Date) -> [FocusSession] {
        sessions.filter { calendar.isDate($0.finishedAt, inSameDayAs: date) }
    }

    func totalFocus(on date: Date) -> TimeInterval {
        sessions(on: date).reduce(0) { $0 + $1.duration }
    }

    func completedCount(on date: Date) -> Int {
        sessions(on: date).filter { $0.completed }.count
    }

    /// 最近 7 天（含今天）按日总专注秒数，索引 0 为 7 天前。
    func lastSevenDaysTotals(reference: Date = Date()) -> [(date: Date, total: TimeInterval)] {
        (0..<7).reversed().map { offset in
            let day = calendar.date(byAdding: .day, value: -offset, to: reference) ?? reference
            return (day, totalFocus(on: day))
        }
    }

    func totalFocusThisWeek(reference: Date = Date()) -> TimeInterval {
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: reference) else {
            return totalFocus(on: reference)
        }
        return sessions
            .filter { $0.finishedAt >= interval.start && $0.finishedAt < interval.end }
            .reduce(0) { $0 + $1.duration }
    }
}