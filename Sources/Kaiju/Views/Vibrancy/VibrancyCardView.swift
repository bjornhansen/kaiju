import SwiftUI

/// Translucent issue card — 3-row layout per the handoff:
/// 1) priority + ID + assignee avatar
/// 2) title (12.5px / 500)
/// 3) labels • comments • estimate
struct VibrancyCardView: View {
    let issue: VibrancyIssue
    var onTap: () -> Void = {}

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                metaRow
                titleRow
                bottomRow
            }
            .padding(.horizontal, VibrancyTokens.Spacing.cardPaddingX)
            .padding(.vertical, VibrancyTokens.Spacing.cardPaddingY)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: VibrancyTokens.Radius.card, style: .continuous)
                    .fill(.regularMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: VibrancyTokens.Radius.card, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.04), radius: 1, x: 0, y: 1)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Rows

    private var metaRow: some View {
        HStack(spacing: 6) {
            VibrancyPriorityIcon(priority: issue.priority, size: 12)
            Text(issue.id)
                .font(.system(size: 10.5, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
            if let user = VibrancySampleData.user(id: issue.assigneeID) {
                VibrancyAvatar(user: user, size: 16)
            }
        }
    }

    private var titleRow: some View {
        Text(issue.title)
            .font(.system(size: 12.5, weight: .medium))
            .foregroundStyle(.primary)
            .lineSpacing(2)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var bottomRow: some View {
        HStack(spacing: 5) {
            ForEach(issue.labels.prefix(2)) { label in
                VibrancyLabelChip(label: label)
            }
            Spacer(minLength: 0)
            if issue.comments > 0 {
                HStack(spacing: 3) {
                    Image(systemName: "bubble.left")
                        .font(.system(size: 10))
                    Text("\(issue.comments)")
                        .font(.system(size: 10.5))
                        .monospacedDigit()
                }
                .foregroundStyle(.secondary)
            }
            Text("\(issue.estimate)")
                .font(.system(size: 10.5, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .padding(.horizontal, 5)
                .padding(.vertical, 1)
                .background(
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(Color.primary.opacity(0.05))
                )
        }
    }
}

// MARK: - Priority icon

/// Linear-style priority glyph, drawn in a 16×16 design grid via `Canvas`
/// so it stays crisp at any size. Matches `primitives.jsx → PriorityIcon`.
struct VibrancyPriorityIcon: View {
    let priority: VibrancyPriority
    let size: CGFloat

    var body: some View {
        Canvas { ctx, _ in
            let scale = size / 16
            let color = priority.color

            switch priority {
            case .urgent:
                let square = Path(
                    roundedRect: CGRect(x: 1.5 * scale, y: 1.5 * scale,
                                        width: 13 * scale, height: 13 * scale),
                    cornerRadius: 3 * scale
                )
                ctx.fill(square, with: .color(color))

                // Vertical bar of the "!"
                let bar = Path { p in
                    p.move(to: CGPoint(x: 8 * scale, y: 4.5 * scale))
                    p.addLine(to: CGPoint(x: 8 * scale, y: 9 * scale))
                }
                ctx.stroke(bar, with: .color(.white),
                           style: StrokeStyle(lineWidth: 1.6 * scale, lineCap: .round))

                // Dot under the bar (a hairline segment with round cap reads as a circle)
                let dot = Path { p in
                    p.move(to: CGPoint(x: 8 * scale, y: 11 * scale))
                    p.addLine(to: CGPoint(x: 8 * scale, y: 11.5 * scale))
                }
                ctx.stroke(dot, with: .color(.white),
                           style: StrokeStyle(lineWidth: 1.6 * scale, lineCap: .round))

            case .none:
                let line = Path { p in
                    p.move(to: CGPoint(x: 3 * scale, y: 8 * scale))
                    p.addLine(to: CGPoint(x: 13 * scale, y: 8 * scale))
                }
                ctx.stroke(line, with: .color(color.opacity(0.5)),
                           style: StrokeStyle(
                               lineWidth: 1.5 * scale,
                               lineCap: .round,
                               dash: [1.8 * scale, 1.8 * scale]
                           ))

            case .high, .med, .low:
                let activeBars = priority == .high ? 3 : (priority == .med ? 2 : 1)
                for i in 0..<3 {
                    let x = (2.0 + Double(i) * 4) * scale
                    let y = (11.0 - Double(i) * 3) * scale
                    let h = (2.0 + Double(i) * 3) * scale
                    let bar = Path(
                        roundedRect: CGRect(x: x, y: y, width: 2.5 * scale, height: h),
                        cornerRadius: 0.5 * scale
                    )
                    ctx.fill(bar, with: .color(color.opacity(i < activeBars ? 1.0 : 0.25)))
                }
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Label chip

struct VibrancyLabelChip: View {
    let label: VibrancyLabel

    var body: some View {
        Text(label.name)
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(label.color)
            .padding(.horizontal, 6)
            .padding(.vertical, 1.5)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(label.color.opacity(0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .strokeBorder(label.color.opacity(0.25), lineWidth: 0.5)
            )
    }
}

// MARK: - Status donut

/// Status indicator drawn as a faded outer ring + a pie-slice that grows with
/// the status's position in the workflow (backlog 0% → done 100% with a
/// checkmark). Drawn in a 16×16 design grid via `Canvas`, matching
/// `primitives.jsx → StatusDot`.
struct VibrancyStatusDonut: View {
    let status: VibrancyStatus
    var size: CGFloat = 12

    var body: some View {
        Canvas { ctx, _ in
            let scale = size / 16
            let center = CGPoint(x: 8 * scale, y: 8 * scale)
            let outerR: CGFloat = 6 * scale
            let color = status.color

            // 1. Faded outer ring — always visible.
            let ring = Path { p in
                p.addArc(center: center, radius: outerR,
                         startAngle: .degrees(0), endAngle: .degrees(360),
                         clockwise: false)
            }
            ctx.stroke(ring, with: .color(color.opacity(0.4)),
                       style: StrokeStyle(lineWidth: 1.5 * scale))

            // 2. Progress fill — backlog: nothing; intermediate: pie slice;
            //    done: full disk + checkmark.
            switch status {
            case .backlog:
                break

            case .done:
                let disk = Path { p in
                    p.addArc(center: center, radius: outerR,
                             startAngle: .degrees(0), endAngle: .degrees(360),
                             clockwise: false)
                }
                ctx.fill(disk, with: .color(color))

                let check = Path { p in
                    p.move(to: CGPoint(x: 5 * scale, y: 8 * scale))
                    p.addLine(to: CGPoint(x: 7 * scale, y: 10 * scale))
                    p.addLine(to: CGPoint(x: 11 * scale, y: 6 * scale))
                }
                ctx.stroke(check, with: .color(.white),
                           style: StrokeStyle(
                               lineWidth: 1.6 * scale,
                               lineCap: .round,
                               lineJoin: .round
                           ))

            case .todo, .doing, .review:
                let pct: Double = {
                    switch status {
                    case .todo:   return 0.25
                    case .doing:  return 0.50
                    case .review: return 0.75
                    default:      return 0
                    }
                }()
                let slice = Path { p in
                    p.move(to: center)
                    p.addArc(
                        center: center,
                        radius: outerR,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(-90 + 360 * pct),
                        clockwise: false
                    )
                    p.closeSubpath()
                }
                ctx.fill(slice, with: .color(color))
            }
        }
        .frame(width: size, height: size)
    }
}
