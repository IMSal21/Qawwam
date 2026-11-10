# Prayer time reference data

| File | Place | Period | Source |
|---|---|---|---|
| `riyadh-2027.csv` | Riyadh | 1 Jan to 31 Dec 2027 | Umm al-Qura yearly export (`PRAYER_TIMES.EXPORT_DATA`), provided by Meshari on 2026-11-10 |

Times are local (Asia/Riyadh), to the minute. The golden tests require every computed time
to be within 1 minute of these values. Never edit a value to make a test pass.
