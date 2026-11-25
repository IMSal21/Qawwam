import Testing

@testable import QawwamCore

@Suite struct SaudiCitiesTests {
    @Test func theMockupsCitiesInOrder() {
        let names: [String] = SaudiCities.all.map(\.arabicName)
        #expect(
            names == [
                "الرياض", "الخرج", "الدرعية", "المجمعة", "بريدة", "عنيزة", "الرس", "مكة المكرمة", "جدة", "الطائف",
                "المدينة المنورة", "ينبع", "الدمام", "الخبر", "الأحساء", "الجبيل", "حفر الباطن", "أبها", "خميس مشيط",
                "تبوك", "حائل", "عرعر", "جازان", "نجران", "الباحة", "سكاكا",
            ])
    }

    @Test func thirteenRegionsInOrder() {
        let groups: [CityGroup] = SaudiCities.grouped(SaudiCities.all)
        let regions: [SaudiRegion] = groups.map(\.region)
        #expect(regions == SaudiRegion.allCases)
        #expect(regions.count == 13)
        let sizes: [Int] = groups.map(\.cities.count)
        #expect(sizes == [4, 3, 3, 2, 5, 2, 1, 1, 1, 1, 1, 1, 1])
    }

    @Test func idsAreUniqueAndFound() {
        let ids: [String] = SaudiCities.all.map(\.id)
        #expect(Set(ids).count == 26)
        #expect(SaudiCities.city(id: "jeddah")?.arabicName == "جدة")
        #expect(SaudiCities.city(id: "nowhere") == nil)
    }

    @Test func everyCityIsInSaudiArabia() {
        for city in SaudiCities.all {
            #expect((16.0...33.0).contains(city.location.latitude), "\(city.id)")
            #expect((34.0...56.0).contains(city.location.longitude), "\(city.id)")
            #expect(!city.englishName.isEmpty)
        }
    }

    @Test func searchIgnoresSpellingVariants() {
        let jeddah: [String] = SaudiCities.search("جده").map(\.id)
        #expect(jeddah == ["jeddah"])
        let ahsa: [String] = SaudiCities.search("الاحساء").map(\.id)
        #expect(ahsa == ["ahsa"])
        let abha: [String] = SaudiCities.search("ابها").map(\.id)
        #expect(abha == ["abha"])
        let tashkeel: [String] = SaudiCities.search("جُدَّة").map(\.id)
        #expect(tashkeel == ["jeddah"])
    }

    @Test func searchInEnglish() {
        let riyadh: [String] = SaudiCities.search("  RIYADH ").map(\.id)
        #expect(riyadh.first == "riyadh")
        let ahsa: [String] = SaudiCities.search("al ahsa").map(\.id)
        #expect(ahsa == ["ahsa"])
    }

    @Test func searchByRegion() {
        let eastern: [String] = SaudiCities.search("الشرقية").map(\.id)
        #expect(eastern == ["dammam", "khobar", "ahsa", "jubail", "hafar-al-batin"])
    }

    @Test func emptyAndUnknownSearches() {
        #expect(SaudiCities.search("") == SaudiCities.all)
        #expect(SaudiCities.search("   ") == SaudiCities.all)
        #expect(SaudiCities.search("abc").isEmpty)
    }

    @Test func nearestCity() {
        #expect(SaudiCities.nearest(to: GeoPoint(latitude: 21.54, longitude: 39.17)).id == "jeddah")
        #expect(SaudiCities.nearest(to: GeoPoint(latitude: 18.32, longitude: 42.76)).id == "khamis-mushait")
        #expect(SaudiCities.nearest(to: GeoPoint(latitude: 24.75, longitude: 46.70)).id == "riyadh")
    }
}
