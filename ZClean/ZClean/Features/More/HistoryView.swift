import SwiftUI

struct HistoryView: View {
    let jobs: [Job]

    var body: some View {
        List {
            if jobs.isEmpty {
                ContentUnavailableView(
                    "No payment history",
                    systemImage: "clock.arrow.circlepath",
                    description: Text("Completed jobs appear here.")
                )
            } else {
                ForEach(jobs) { job in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(JobStore.decryptedName(for: job.contact))
                                .font(.headline)
                            Text((job.completedAt ?? job.createdAt), format: .dateTime.day().month().year())
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Label {
                            Text(Currency.gbp(job.cashAmount ?? job.expectedAmount))
                        } icon: {
                            Image(systemName: "sterlingsign.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Past payments")
    }
}
