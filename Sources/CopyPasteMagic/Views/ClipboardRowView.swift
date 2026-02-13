import SwiftUI

struct ClipboardRowView: View {
    let entry: ClipboardEntry
    var isSelected: Bool = false

    var body: some View {
        HStack(spacing: 10) {
            if entry.type == .image {
                Text("🖼️")
                    .frame(width: 20)
            } else {
                Image(systemName: entry.typeIcon)
                    .foregroundStyle(isSelected ? .white : .secondary)
                    .frame(width: 20)
            }

            VStack(alignment: .leading, spacing: 4) {
                if entry.type == .image, let url = entry.imageURL,
                   let nsImage = NSImage(contentsOf: url) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 80)
                        .cornerRadius(4)

                    Text(entry.preview)
                        .lineLimit(1)
                        .font(.caption)
                        .foregroundStyle(isSelected ? .white.opacity(0.7) : .secondary)
                } else {
                    Text(entry.preview)
                        .lineLimit(2)
                        .font(.system(.body, design: .monospaced))
                        .truncationMode(.tail)
                        .foregroundStyle(isSelected ? .white : .primary)
                }

                Text(entry.relativeTime)
                    .font(.caption)
                    .foregroundStyle(isSelected ? AnyShapeStyle(.white.opacity(0.7)) : AnyShapeStyle(.tertiary))
            }

            Spacer()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.accentColor : Color.clear)
        )
        .contentShape(Rectangle())
    }
}
