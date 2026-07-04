# ZClean

An iOS app I built for my mum's cleaning business. She was tracking jobs, hours, and cash payments across scattered notes, so I made one place for all of it: log a job, track when it's done, and see what's been paid and what's still owed.

Built with SwiftUI and Cursor as an AI pair programmer — I directed the features and reviewed the code.

## Features

- **Dashboard** — upcoming jobs sorted by how soon they are, with this month's earnings at a glance
- **Quick add** — log a job in a few taps: client, date, time, expected amount, with weekly recurrence for regular clients
- **Job management** — edit, complete, or delete jobs; completed jobs record what was actually paid
- **History** — past jobs with hours worked and cash received
- **Reminders** — local notifications before upcoming jobs

## How it's built

- **SwiftUI** for all UI, organised by feature (`Dashboard`, `Jobs`, `More`)
- **SwiftData** for persistence (`Job` and `Contact` models)
- **Client name encryption** — client names are real people's personal data, so they're encrypted at rest with AES-GCM (CryptoKit), with the key stored in the iOS Keychain. The key uses `kSecAttrAccessibleAfterFirstUnlock` (not `ThisDeviceOnly`) so encrypted backups restore correctly on a new phone.
- **UserNotifications** for job reminders
- Unit tests covering job sorting, monthly earnings, and recurrence serialization

## Requirements

- Xcode 26+
- iOS 26+

## Running it

1. Clone the repo:

   ```bash
   git clone https://github.com/Jackkamin/ZClean.git
   ```

2. Open `ZClean/ZClean.xcodeproj` in Xcode
3. Build and run on a simulator or device
