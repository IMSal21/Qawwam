import Foundation

/// The 13 regions of Saudi Arabia, in the order the city picker lists them.
public enum SaudiRegion: String, CaseIterable, Sendable {
    case riyadh, qassim, makkah, madinah, eastern, asir, tabuk, hail, northernBorders, jazan, najran, baha, jouf

    var arabicName: String {
        switch self {
        case .riyadh: "الرياض"
        case .qassim: "القصيم"
        case .makkah: "مكة المكرمة"
        case .madinah: "المدينة المنورة"
        case .eastern: "الشرقية"
        case .asir: "عسير"
        case .tabuk: "تبوك"
        case .hail: "حائل"
        case .northernBorders: "الحدود الشمالية"
        case .jazan: "جازان"
        case .najran: "نجران"
        case .baha: "الباحة"
        case .jouf: "الجوف"
        }
    }

    var englishName: String {
        switch self {
        case .riyadh: "Riyadh"
        case .qassim: "Al-Qassim"
        case .makkah: "Makkah"
        case .madinah: "Madinah"
        case .eastern: "Eastern"
        case .asir: "Asir"
        case .tabuk: "Tabuk"
        case .hail: "Hail"
        case .northernBorders: "Northern Borders"
        case .jazan: "Jazan"
        case .najran: "Najran"
        case .baha: "Al-Bahah"
        case .jouf: "Al-Jouf"
        }
    }
}

/// A city the prayer times can be worked out for.
public struct City: Equatable, Identifiable, Sendable {
    public let id: String
    public let region: SaudiRegion
    public let arabicName: String
    public let englishName: String
    public let location: GeoPoint

    public init(id: String, region: SaudiRegion, arabicName: String, englishName: String, location: GeoPoint) {
        self.id = id
        self.region = region
        self.arabicName = arabicName
        self.englishName = englishName
        self.location = location
    }
}

/// Cities of one region, for the picker's headings.
public struct CityGroup: Equatable, Sendable {
    public let region: SaudiRegion
    public let cities: [City]
}

/// The cities on the onboarding picker, with search and the nearest city to a point.
public enum SaudiCities {
    public static let riyadh = all[0]

    public static let all: [City] = [
        city("riyadh", .riyadh, "الرياض", "Riyadh", 24.7136, 46.6753),
        city("kharj", .riyadh, "الخرج", "Al-Kharj", 24.1556, 47.3120),
        city("diriyah", .riyadh, "الدرعية", "Diriyah", 24.7340, 46.5750),
        city("majmaah", .riyadh, "المجمعة", "Al-Majmaah", 25.9039, 45.3456),
        city("buraydah", .qassim, "بريدة", "Buraydah", 26.3260, 43.9750),
        city("unaizah", .qassim, "عنيزة", "Unaizah", 26.0843, 43.9935),
        city("rass", .qassim, "الرس", "Ar-Rass", 25.8693, 43.4973),
        city("makkah", .makkah, "مكة المكرمة", "Makkah", 21.3891, 39.8579),
        city("jeddah", .makkah, "جدة", "Jeddah", 21.4858, 39.1925),
        city("taif", .makkah, "الطائف", "Taif", 21.2703, 40.4158),
        city("madinah", .madinah, "المدينة المنورة", "Madinah", 24.5247, 39.5692),
        city("yanbu", .madinah, "ينبع", "Yanbu", 24.0895, 38.0618),
        city("dammam", .eastern, "الدمام", "Dammam", 26.4207, 50.0888),
        city("khobar", .eastern, "الخبر", "Al-Khobar", 26.2172, 50.1971),
        city("ahsa", .eastern, "الأحساء", "Al-Ahsa", 25.3833, 49.5860),
        city("jubail", .eastern, "الجبيل", "Jubail", 27.0046, 49.6460),
        city("hafar-al-batin", .eastern, "حفر الباطن", "Hafar Al-Batin", 28.4328, 45.9708),
        city("abha", .asir, "أبها", "Abha", 18.2164, 42.5053),
        city("khamis-mushait", .asir, "خميس مشيط", "Khamis Mushait", 18.3060, 42.7290),
        city("tabuk", .tabuk, "تبوك", "Tabuk", 28.3835, 36.5662),
        city("hail", .hail, "حائل", "Hail", 27.5114, 41.7208),
        city("arar", .northernBorders, "عرعر", "Arar", 30.9753, 41.0381),
        city("jazan", .jazan, "جازان", "Jazan", 16.8892, 42.5511),
        city("najran", .najran, "نجران", "Najran", 17.4924, 44.1277),
        city("baha", .baha, "الباحة", "Al-Bahah", 20.0129, 41.4677),
        city("sakaka", .jouf, "سكاكا", "Sakaka", 29.9697, 40.2064),
    ]

    public static func city(id: String) -> City? {
        all.first { $0.id == id }
    }

    /// Cities whose name or region contains `text`, in either language. Case, tashkeel, spaces and hyphens are
    /// ignored, and أ إ آ match ا, ة matches ه, and ى matches ي. Empty text gives every city.
    public static func search(_ text: String) -> [City] {
        let query = normalized(text)
        guard !query.isEmpty else { return all }
        return all.filter { city in
            let names = [city.arabicName, city.englishName, city.region.arabicName, city.region.englishName]
            return names.contains { normalized($0).contains(query) }
        }
    }

    /// The listed city closest to `point`.
    public static func nearest(to point: GeoPoint) -> City {
        all.min { distance($0.location, point) < distance($1.location, point) }!
    }

    /// `cities` under their regions, in the regions' order. Regions with no city are left out.
    public static func grouped(_ cities: [City]) -> [CityGroup] {
        SaudiRegion.allCases.compactMap { region in
            let inRegion = cities.filter { $0.region == region }
            return inRegion.isEmpty ? nil : CityGroup(region: region, cities: inRegion)
        }
    }

    static func normalized(_ text: String) -> String {
        var result = ""
        for scalar in text.lowercased().unicodeScalars {
            switch scalar.value {
            case 0x064B...0x065F, 0x0670, 0x0640, 0x20, 0x2D: continue
            case 0x0623, 0x0625, 0x0622: result.unicodeScalars.append("\u{0627}")
            case 0x0629: result.unicodeScalars.append("\u{0647}")
            case 0x0649: result.unicodeScalars.append("\u{064A}")
            default: result.unicodeScalars.append(scalar)
            }
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Squared distance on a flat map, with longitude shrunk by latitude. Close enough to rank cities.
    private static func distance(_ a: GeoPoint, _ b: GeoPoint) -> Double {
        let shrink = cos((a.latitude + b.latitude) / 2 * .pi / 180)
        let dLat = a.latitude - b.latitude
        let dLon = (a.longitude - b.longitude) * shrink
        return dLat * dLat + dLon * dLon
    }

    private static func city(
        _ id: String, _ region: SaudiRegion, _ arabic: String, _ english: String, _ latitude: Double,
        _ longitude: Double
    ) -> City {
        City(
            id: id, region: region, arabicName: arabic, englishName: english,
            location: GeoPoint(latitude: latitude, longitude: longitude))
    }
}
