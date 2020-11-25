import WidgetKit
import SwiftUI


struct Provider: TimelineProvider {

    let service = HomeWidgetTodayRemoteService()

    func placeholder(in context: Context) -> HomeWidgetTodayData {
        Constants.staticContent
    }

    func getSnapshot(in context: Context, completion: @escaping (HomeWidgetTodayData) -> ()) {
        getSnapshotData(completion: completion)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        getTimelineData(completion: completion)
    }
}

// MARK: - Widget data
private extension Provider {

    func getSnapshotData(completion: @escaping (HomeWidgetTodayData) -> ()) {

        completion(widgetData ?? Constants.staticContent)
    }

    func getTimelineData(completion: @escaping (Timeline<Entry>) -> ()) {

        let date = Date()
        let nextRefreshDate = Calendar.current.date(byAdding: .minute, value: Constants.refreshInterval, to: date) ?? date

        var entry = widgetData ?? Constants.staticContent

        let elapsedTime = abs(Calendar.current.dateComponents([.minute], from: entry.date, to: date).minute ?? 0)

        // if cached data are "too old", refresh them from the backend, otherwise keep them
        guard elapsedTime > Constants.minElapsedTimeToRefresh else {

            let timeline = Timeline(entries: [entry], policy: .after(nextRefreshDate))
            completion(timeline)
            return
        }

        service.fetchStats(for: entry) { result in

            switch result {
            case .failure(let error):
                DDLogError("HomeWidgetToday: failed to fetch remote stats. Returned error: \(error.localizedDescription)")
            case .success(let widgetData):

                DispatchQueue.global().async {
                    // update the item in the local cache
                    HomeWidgetTodayData.setItem(item: entry)
                }
                entry = widgetData
            }

            let timeline = Timeline(entries: [entry], policy: .after(nextRefreshDate))
            completion(timeline)
        }
    }

    private var defaultSiteID: Int? {
        // TODO - TODAYWIDGET: taking the default site id from user defaults for now.
        // This would change if the old widget gets reconfigured to a different site than the default.
        // This will be updated with the configuration intent.
        UserDefaults(suiteName: WPAppGroupName)?.object(forKey: WPStatsTodayWidgetUserDefaultsSiteIdKey) as? Int
    }

    private var widgetData: HomeWidgetTodayData? {
        // TODO - TODAYWIDGET: we might change this, but for now an ID equal to zero should not return any valid data
        HomeWidgetTodayData.read()?[defaultSiteID ?? 0]
    }
}

// MARK: - Constants
private extension Provider {
    enum Constants {
        // TODO - TODAYWIDGET: This can serve as static content to display in the preview if no data are yet available
        // we should define what to put in here
        static let staticContent = HomeWidgetTodayData(siteID: 0,
                                                       siteName: "Places you should visit",
                                                       url: "",
                                                       timeZone: TimeZone.current,
                                                       date: Date(),
                                                       stats: TodayWidgetStats(views: 5980,
                                                                               visitors: 4208,
                                                                               likes: 107,
                                                                               comments: 5))
        // refresh interval of the widget, in minutes
        static let refreshInterval = 60
        // minimum elapsed time, in minutes, before new data are fetched from the backend.
        static let minElapsedTimeToRefresh = 10
    }
}


@main
struct WordPressHomeWidgetToday: Widget {

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WPHomeWidgetTodayKind, provider: Provider()) { entry in
            TodayWidgetView(content: entry)
        }
        .configurationDisplayName("Today")
        .description("Stay up to date with today's activity on your WordPress site.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
