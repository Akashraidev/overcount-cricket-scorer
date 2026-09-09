import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../data/models/batting_stat.dart';
import '../../data/models/bowling_stat.dart';
import '../../data/models/innings.dart';
import '../../data/models/match.dart';
import '../../data/models/team.dart';
import 'date_formatter.dart';

class PdfScorecardGenerator {
  PdfScorecardGenerator._();

  static Future<void> generateAndPrint({
    required CricketMatch match,
    required Team teamA,
    required Team teamB,
    required List<Innings> allInnings,
    required Map<String, List<BattingStat>> battingStatsMap,
    required Map<String, List<BowlingStat>> bowlingStatsMap,
  }) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFDC2626),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'CRICKET MATCH SCORECARD',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  match.title,
                  style: pw.TextStyle(color: PdfColors.white, fontSize: 14),
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Venue: ${match.venue}',
                      style: const pw.TextStyle(color: PdfColors.white, fontSize: 10),
                    ),
                    pw.Text(
                      'Date: ${DateFormatter.formatDate(DateTime.fromMillisecondsSinceEpoch(match.matchDate))}',
                      style: const pw.TextStyle(color: PdfColors.white, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // Match Result
          if (match.resultSummary != null) ...[
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(0xFFFEF2F2),
                border: pw.Border.all(color: const PdfColor.fromInt(0xFFDC2626)),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(
                'Result: ${match.resultSummary}',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: const PdfColor.fromInt(0xFF991B1B),
                ),
              ),
            ),
            pw.SizedBox(height: 16),
          ],

          // Innings Sections
          for (final inn in allInnings) ...[
            _buildInningsPdfSection(
              inn: inn,
              teamA: teamA,
              teamB: teamB,
              battingStats: battingStatsMap[inn.id] ?? [],
              bowlingStats: bowlingStatsMap[inn.id] ?? [],
            ),
            pw.SizedBox(height: 20),
          ],
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => doc.save(),
      name: '${match.title.replaceAll(' ', '_')}_Scorecard.pdf',
    );
  }

  static pw.Widget _buildInningsPdfSection({
    required Innings inn,
    required Team teamA,
    required Team teamB,
    required List<BattingStat> battingStats,
    required List<BowlingStat> bowlingStats,
  }) {
    final battingTeamName = inn.battingTeamId == teamA.id ? teamA.name : teamB.name;
    final isFirstInnings = inn.inningsNumber == 1;

    final total4s = battingStats.fold<int>(0, (sum, b) => sum + b.fours);
    final total6s = battingStats.fold<int>(0, (sum, b) => sum + b.sixes);
    final boundaryRuns = (total4s * 4) + (total6s * 6);
    final boundaryPct = inn.totalRuns > 0 ? ((boundaryRuns / inn.totalRuns) * 100).toStringAsFixed(0) : '0';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Innings Title Banner (Blue for Innings 1, Crimson for Innings 2)
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          decoration: pw.BoxDecoration(
            color: isFirstInnings ? const PdfColor.fromInt(0xFF1E3A8A) : const PdfColor.fromInt(0xFF991B1B),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Innings ${inn.inningsNumber}: $battingTeamName',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: PdfColors.white),
              ),
              pw.Text(
                '${inn.totalRuns}/${inn.totalWickets} (${inn.oversDisplay} Ov)',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: PdfColors.white),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 8),

        // Batting Table
        pw.Text('Batting', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
        pw.SizedBox(height: 4),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
          children: [
            // Header
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _tableHeaderCell('Batter', flex: 3),
                _tableHeaderCell('Dismissal', flex: 3),
                _tableHeaderCell('R', align: pw.TextAlign.right),
                _tableHeaderCell('B', align: pw.TextAlign.right),
                _tableHeaderCell('4s', align: pw.TextAlign.right, textColor: const PdfColor.fromInt(0xFF2563EB)),
                _tableHeaderCell('6s', align: pw.TextAlign.right, textColor: const PdfColor.fromInt(0xFF7C3AED)),
                _tableHeaderCell('SR', align: pw.TextAlign.right),
              ],
            ),
            // Rows
            for (final b in battingStats)
              pw.TableRow(
                children: [
                  _tableBodyCell(b.playerName, flex: 3),
                  _tableBodyCell(b.dismissalSummary, flex: 3, isMuted: true),
                  _tableBodyCell('${b.runs}', align: pw.TextAlign.right, isBold: true),
                  _tableBodyCell('${b.balls}', align: pw.TextAlign.right),
                  _tableBodyCell(
                    '${b.fours}',
                    align: pw.TextAlign.right,
                    textColor: b.fours > 0 ? const PdfColor.fromInt(0xFF2563EB) : null,
                    isBold: b.fours > 0,
                  ),
                  _tableBodyCell(
                    '${b.sixes}',
                    align: pw.TextAlign.right,
                    textColor: b.sixes > 0 ? const PdfColor.fromInt(0xFF7C3AED) : null,
                    isBold: b.sixes > 0,
                  ),
                  _tableBodyCell(b.strikeRate.toStringAsFixed(1), align: pw.TextAlign.right),
                ],
              ),
          ],
        ),

        // Innings Boundary Highlights Summary Bar
        pw.SizedBox(height: 6),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(4),
            border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                '4s: $total4s (${total4s * 4} r)',
                style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF2563EB)),
              ),
              pw.Text(
                '6s: $total6s (${total6s * 6} r)',
                style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF7C3AED)),
              ),
              pw.Text(
                'Boundaries: $boundaryRuns runs ($boundaryPct%)',
                style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
              ),
              pw.Text(
                'Extras: ${inn.totalExtras} (wd ${inn.wides}, nb ${inn.noBalls}, b ${inn.byes}, lb ${inn.legByes})',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
              ),
              pw.Text(
                'CRR: ${inn.currentRunRate.toStringAsFixed(2)}',
                style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 8),

        // Bowling Table
        pw.Text('Bowling', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
        pw.SizedBox(height: 4),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _tableHeaderCell('Bowler', flex: 3),
                _tableHeaderCell('O', align: pw.TextAlign.right),
                _tableHeaderCell('M', align: pw.TextAlign.right),
                _tableHeaderCell('R', align: pw.TextAlign.right),
                _tableHeaderCell('W', align: pw.TextAlign.right, textColor: const PdfColor.fromInt(0xFFDC2626)),
                _tableHeaderCell('ECO', align: pw.TextAlign.right),
              ],
            ),
            for (final bw in bowlingStats)
              pw.TableRow(
                children: [
                  _tableBodyCell(bw.playerName, flex: 3),
                  _tableBodyCell(bw.oversDisplay, align: pw.TextAlign.right),
                  _tableBodyCell('${bw.maidens}', align: pw.TextAlign.right),
                  _tableBodyCell('${bw.runsConceded}', align: pw.TextAlign.right),
                  _tableBodyCell(
                    '${bw.wickets}',
                    align: pw.TextAlign.right,
                    isBold: true,
                    textColor: bw.wickets > 0 ? const PdfColor.fromInt(0xFFDC2626) : null,
                  ),
                  _tableBodyCell(bw.economy.toStringAsFixed(2), align: pw.TextAlign.right),
                ],
              ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _tableHeaderCell(
    String text, {
    int flex = 1,
    pw.TextAlign align = pw.TextAlign.left,
    PdfColor? textColor,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          color: textColor ?? PdfColors.black,
        ),
      ),
    );
  }

  static pw.Widget _tableBodyCell(
    String text, {
    int flex = 1,
    pw.TextAlign align = pw.TextAlign.left,
    bool isBold = false,
    bool isMuted = false,
    PdfColor? textColor,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: textColor ?? (isMuted ? PdfColors.grey600 : PdfColors.black),
        ),
      ),
    );
  }
}
