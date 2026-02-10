import SwiftUI

struct StatusIcon: View {
    let systemName: String
    let status: PermissionStatus

    enum PermissionStatus {
        case granted
        case denied
        case pending

        var color: Color {
            switch self {
            case .granted: return .green
            case .denied: return .red
            case .pending: return .orange
            }
        }
    }

    init(systemName: String, status: PermissionStatus) {
        self.systemName = systemName
        self.status = status
    }

    var body: some View {
        Image(systemName: systemName)
            .foregroundColor(status.color)
    }
}
