import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../data/models/ball.dart';
import '../../data/models/batting_stat.dart';
import '../../data/models/bowling_stat.dart';
import '../../data/models/fall_of_wicket.dart';
import '../../data/models/innings.dart';
import '../../data/models/match.dart';
import '../../data/models/over_summary.dart';
import '../../data/models/partnership.dart';
import '../../data/models/team.dart';
import 'date_formatter.dart';

class PdfScorecardGenerator {
  PdfScorecardGenerator._();

  // Neutral Palette
  static const PdfColor _navyDark = PdfColor.fromInt(0xFF0F172A);
  static const PdfColor _navySlate = PdfColor.fromInt(0xFF1E293B);
  static const PdfColor _crimson = PdfColor.fromInt(0xFFDC2626);
  static const PdfColor _emerald = PdfColor.fromInt(0xFF059669);
  static const PdfColor _gold = PdfColor.fromInt(0xFFD97706);
  static const PdfColor _blue4s = PdfColor.fromInt(0xFF2563EB);
  static const PdfColor _purple6s = PdfColor.fromInt(0xFF7C3AED);
  static const PdfColor _tableHeaderBg = PdfColor.fromInt(0xFFF1F5F9);
  static const PdfColor _tableAltBg = PdfColor.fromInt(0xFFF8FAFC);
  static const PdfColor _borderColor = PdfColor.fromInt(0xFFE2E8F0);
  static const PdfColor _textMuted = PdfColor.fromInt(0xFF64748B);

  // ---------------------------------------------------------------------------
  // Color Helpers for Dynamic Team Theming
  // ---------------------------------------------------------------------------
  static PdfColor _getTeamColor(Team team, {PdfColor fallback = _navySlate}) {
    if (team.colorValue != 0) {
      return PdfColor.fromInt(team.colorValue);
    }
    return fallback;
  }

  static String _toHex(PdfColor color) {
    final r = (color.red * 255).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
    final g = (color.green * 255).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
    final b = (color.blue * 255).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
    return '#$r$g$b'.toUpperCase();
  }

  /// Blends color with white to create soft pastel background tints
  static PdfColor _tintColor(PdfColor color, double factor) {
    final r = (1.0 - factor) * 1.0 + factor * color.red;
    final g = (1.0 - factor) * 1.0 + factor * color.green;
    final b = (1.0 - factor) * 1.0 + factor * color.blue;
    return PdfColor(r.clamp(0.0, 1.0), g.clamp(0.0, 1.0), b.clamp(0.0, 1.0));
  }

  // ---------------------------------------------------------------------------
  // Vector SVG Icons (100% Reliable, Never Misses Glyphs, Works on All Printers)
  // ---------------------------------------------------------------------------
  static pw.Widget _svgIcon(String svgData, {double width = 12, double height = 12}) {
    return pw.Container(
      width: width,
      height: height,
      child: pw.SvgImage(svg: svgData),
    );
  }

  static pw.Widget _trophyIcon({PdfColor color = _gold, double size = 13}) {
    final hex = _toHex(color);
    return _svgIcon(
      '<svg viewBox="0 0 24 24" width="$size" height="$size">'
      '<path fill="$hex" d="M19 5h-2V3H7v2H5c-1.1 0-2 .9-2 2v1c0 2.55 1.92 4.63 4.39 4.94A5.01 5.01 0 0 0 11 15.9V18H8v2h8v-2h-3v-2.1c1.86-.47 3.25-2.02 3.61-3.96A5.002 5.002 0 0 0 21 8V7c0-1.1-.9-2-2-2zM5 8V7h2v3.82C5.84 10.4 5 9.3 5 8zm14 0c0 1.3-.84 2.4-2 2.82V7h2v1z"/>'
      '</svg>',
      width: size,
      height: size,
    );
  }

  static pw.Widget _cricketBatBallIcon({PdfColor color = PdfColors.white, double size = 12}) {
    final hex = _toHex(color);
    return _svgIcon(
      '<svg viewBox="0 0 24 24" width="$size" height="$size">'
      '<path fill="$hex" d="M19.4 4.6a2 2 0 0 0-2.8 0l-9.8 9.8 2.8 2.8 9.8-9.8a2 2 0 0 0 0-2.8zM5.4 17.2l-2 2a1 1 0 0 0 0 1.4l.2.2a1 1 0 0 0 1.4 0l2-2-1.6-1.6z"/>'
      '<circle fill="$hex" cx="18" cy="18" r="3"/>'
      '</svg>',
      width: size,
      height: size,
    );
  }

  static pw.Widget _venuePinIcon({PdfColor color = const PdfColor.fromInt(0xFF94A3B8)}) {
    final hex = _toHex(color);
    return _svgIcon(
      '<svg viewBox="0 0 24 24" width="10" height="10">'
      '<path fill="$hex" d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5a2.5 2.5 0 0 1 0-5 2.5 2.5 0 0 1 0 5z"/>'
      '</svg>',
      width: 10,
      height: 10,
    );
  }

  static pw.Widget _calendarIcon({PdfColor color = const PdfColor.fromInt(0xFF94A3B8)}) {
    final hex = _toHex(color);
    return _svgIcon(
      '<svg viewBox="0 0 24 24" width="10" height="10">'
      '<path fill="$hex" d="M19 4h-1V2h-2v2H8V2H6v2H5c-1.11 0-1.99.9-1.99 2L3 20a2 2 0 0 0 2 2h14c1.1 0 2-.9 2-2V6c0-1.1-.9-2-2-2zm0 16H5V9h14v11zM7 11h5v5H7z"/>'
      '</svg>',
      width: 10,
      height: 10,
    );
  }

  static pw.Widget _coinIcon({PdfColor color = const PdfColor.fromInt(0xFF94A3B8)}) {
    final hex = _toHex(color);
    return _svgIcon(
      '<svg viewBox="0 0 24 24" width="10" height="10">'
      '<circle fill="$hex" cx="12" cy="12" r="9"/>'
      '</svg>',
      width: 10,
      height: 10,
    );
  }

  static pw.Widget _batIcon({PdfColor color = _navySlate}) {
    final hex = _toHex(color);
    return _svgIcon(
      '<svg viewBox="0 0 24 24" width="11" height="11">'
      '<path fill="$hex" d="M19.4 4.6a2 2 0 0 0-2.8 0l-9.8 9.8 2.8 2.8 9.8-9.8a2 2 0 0 0 0-2.8zm-14 12.6l-2 2a1 1 0 0 0 0 1.4l.2.2a1 1 0 0 0 1.4 0l2-2-1.6-1.6z"/>'
      '</svg>',
      width: 11,
      height: 11,
    );
  }

  static pw.Widget _ballIcon({PdfColor color = _navySlate}) {
    final hex = _toHex(color);
    return _svgIcon(
      '<svg viewBox="0 0 24 24" width="11" height="11">'
      '<circle fill="$hex" cx="12" cy="12" r="9"/>'
      '</svg>',
      width: 11,
      height: 11,
    );
  }

  static pw.Widget _stumpsIcon({PdfColor color = _crimson}) {
    final hex = _toHex(color);
    return _svgIcon(
      '<svg viewBox="0 0 24 24" width="11" height="11">'
      '<rect fill="$hex" x="4" y="3" width="16" height="2" rx="0.5"/>'
      '<rect fill="$hex" x="5.5" y="5" width="2" height="16" rx="0.5"/>'
      '<rect fill="$hex" x="11" y="5" width="2" height="16" rx="0.5"/>'
      '<rect fill="$hex" x="16.5" y="5" width="2" height="16" rx="0.5"/>'
      '</svg>',
      width: 11,
      height: 11,
    );
  }

  static pw.Widget _partnershipIcon({PdfColor color = _navySlate}) {
    final hex = _toHex(color);
    return _svgIcon(
      '<svg viewBox="0 0 24 24" width="11" height="11">'
      '<path fill="$hex" d="M16 11c1.66 0 2.99-1.34 2.99-3S17.66 5 16 5s-3 1.34-3 3 1.34 3 3 3zm-8 0c1.66 0 2.99-1.34 2.99-3S9.66 5 8 5 5 6.34 5 8s1.34 3 3 3zm0 2c-2.33 0-7 1.17-7 3.5V19h14v-2.5c0-2.33-4.67-3.5-7-3.5zm8 0c-.29 0-.62.02-.97.05 1.16.84 1.97 1.97 1.97 3.45V19h6v-2.5c0-2.33-4.67-3.5-7-3.5z"/>'
      '</svg>',
      width: 11,
      height: 11,
    );
  }

  static pw.Widget _sequenceIcon({PdfColor color = _navySlate}) {
    final hex = _toHex(color);
    return _svgIcon(
      '<svg viewBox="0 0 24 24" width="11" height="11">'
      '<circle fill="$hex" cx="12" cy="12" r="9"/>'
      '</svg>',
      width: 11,
      height: 11,
    );
  }

  // ---------------------------------------------------------------------------
  // Build Full Scorecard PDF Document
  // ---------------------------------------------------------------------------
  static pw.Document buildPdfDocument({
    required CricketMatch match,
    required Team teamA,
    required Team teamB,
    required List<Innings> allInnings,
    required Map<String, List<BattingStat>> battingStatsMap,
    required Map<String, List<BowlingStat>> bowlingStatsMap,
    Map<String, List<FallOfWicket>>? fallOfWicketsMap,
    Map<String, List<Partnership>>? partnershipsMap,
    Map<String, List<OverSummary>>? overSummariesMap,
  }) {
    final fowMap = fallOfWicketsMap ?? {};
    final partMap = partnershipsMap ?? {};
    final overMap = overSummariesMap ?? {};

    final teamAColor = _getTeamColor(teamA, fallback: const PdfColor.fromInt(0xFF1D4ED8));
    final teamBColor = _getTeamColor(teamB, fallback: const PdfColor.fromInt(0xFFB91C1C));

    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 26, vertical: 24),
        header: (context) => _buildPageHeader(match, teamA, teamB, teamAColor, teamBColor, context),
        footer: (context) => _buildPageFooter(teamAColor, teamBColor, context),
        build: (context) => [
          // 1. Team-Themed Match Masthead
          _buildMatchMasthead(match, teamA, teamB, teamAColor, teamBColor),
          pw.SizedBox(height: 10),

          // 2. Result or Status Banner (Dynamically Themed with Winner's Team Color)
          _buildResultBanner(match, teamA, teamB, teamAColor, teamBColor),
          pw.SizedBox(height: 10),

          // 3. Teams Overview with Team Color Themes
          _buildTeamsCard(match, teamA, teamB, teamAColor, teamBColor),
          pw.SizedBox(height: 14),

          // 4. Per-Innings Sections (Themed with Batting & Bowling Teams' Colors)
          for (int i = 0; i < allInnings.length; i++) ...[
            _buildInningsSection(
              inn: allInnings[i],
              match: match,
              teamA: teamA,
              teamB: teamB,
              teamAColor: teamAColor,
              teamBColor: teamBColor,
              battingStats: battingStatsMap[allInnings[i].id] ?? [],
              bowlingStats: bowlingStatsMap[allInnings[i].id] ?? [],
              fallOfWickets: fowMap[allInnings[i].id] ?? [],
              partnerships: partMap[allInnings[i].id] ?? [],
              overSummaries: overMap[allInnings[i].id] ?? [],
            ),
            if (i < allInnings.length - 1) pw.SizedBox(height: 16),
          ],
        ],
      ),
    );

    return doc;
  }

  /// Generates the PDF document and opens the native printing / export dialog
  static Future<void> generateAndPrint({
    required CricketMatch match,
    required Team teamA,
    required Team teamB,
    required List<Innings> allInnings,
    required Map<String, List<BattingStat>> battingStatsMap,
    required Map<String, List<BowlingStat>> bowlingStatsMap,
    Map<String, List<FallOfWicket>>? fallOfWicketsMap,
    Map<String, List<Partnership>>? partnershipsMap,
    Map<String, List<OverSummary>>? overSummariesMap,
  }) async {
    final doc = buildPdfDocument(
      match: match,
      teamA: teamA,
      teamB: teamB,
      allInnings: allInnings,
      battingStatsMap: battingStatsMap,
      bowlingStatsMap: bowlingStatsMap,
      fallOfWicketsMap: fallOfWicketsMap,
      partnershipsMap: partnershipsMap,
      overSummariesMap: overSummariesMap,
    );

    await Printing.layoutPdf(
      onLayout: (format) async => doc.save(),
      name: '${match.title.replaceAll(' ', '_')}_Scorecard.pdf',
    );
  }

  // ---------------------------------------------------------------------------
  // Page Header (Subsequent pages only)
  // ---------------------------------------------------------------------------
  static pw.Widget _buildPageHeader(
    CricketMatch match,
    Team teamA,
    Team teamB,
    PdfColor teamAColor,
    PdfColor teamBColor,
    pw.Context context,
  ) {
    if (context.pageNumber <= 1) {
      return pw.SizedBox.shrink();
    }
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.only(bottom: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _borderColor, width: 0.8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Row(
            children: [
              pw.Container(width: 6, height: 6, decoration: pw.BoxDecoration(color: teamAColor, shape: pw.BoxShape.circle)),
              pw.SizedBox(width: 4),
              pw.Text(
                teamA.shortName.isNotEmpty ? teamA.shortName : teamA.name,
                style: pw.TextStyle(fontSize: 8.5, color: _navyDark, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(' vs ', style: const pw.TextStyle(fontSize: 8.5, color: _textMuted)),
              pw.Container(width: 6, height: 6, decoration: pw.BoxDecoration(color: teamBColor, shape: pw.BoxShape.circle)),
              pw.SizedBox(width: 4),
              pw.Text(
                teamB.shortName.isNotEmpty ? teamB.shortName : teamB.name,
                style: pw.TextStyle(fontSize: 8.5, color: _navyDark, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(' | Official Scorecard', style: const pw.TextStyle(fontSize: 8.5, color: _textMuted)),
            ],
          ),
          pw.Text(
            match.venue,
            style: const pw.TextStyle(fontSize: 8.5, color: _textMuted),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Page Footer (All pages with Team Colors Accent)
  // ---------------------------------------------------------------------------
  static pw.Widget _buildPageFooter(PdfColor teamAColor, PdfColor teamBColor, pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Column(
        children: [
          pw.Row(
            children: [
              pw.Expanded(child: pw.Container(height: 1.5, color: teamAColor)),
              pw.Expanded(child: pw.Container(height: 1.5, color: teamBColor)),
            ],
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 6),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'OverCount Cricket Scorer | Official Match Report',
                  style: const pw.TextStyle(fontSize: 7.5, color: _textMuted),
                ),
                pw.Text(
                  'Generated: ${DateFormatter.formatDate(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 7.5, color: _textMuted),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: pw.TextStyle(fontSize: 7.5, color: _navySlate, fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. Team-Themed Match Masthead
  // ---------------------------------------------------------------------------
  static pw.Widget _buildMatchMasthead(
    CricketMatch match,
    Team teamA,
    Team teamB,
    PdfColor teamAColor,
    PdfColor teamBColor,
  ) {
    final tossTeam = match.tossWinnerTeamId == teamA.id
        ? teamA.name
        : (match.tossWinnerTeamId == teamB.id ? teamB.name : null);

    return pw.Container(
      decoration: pw.BoxDecoration(
        color: _navyDark,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Team Color Dual-Tone Accent Top Stripe
          pw.Container(
            height: 4,
            child: pw.Row(
              children: [
                pw.Expanded(child: pw.Container(color: teamAColor)),
                pw.Expanded(child: pw.Container(color: teamBColor)),
              ],
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Row(
                      children: [
                        _cricketBatBallIcon(color: const PdfColor.fromInt(0xFF94A3B8), size: 10),
                        pw.SizedBox(width: 5),
                        pw.Text(
                          'OVERCOUNT CRICKET | OFFICIAL MATCH REPORT',
                          style: pw.TextStyle(
                            color: const PdfColor.fromInt(0xFF94A3B8),
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                      decoration: pw.BoxDecoration(
                        color: _navySlate,
                        borderRadius: pw.BorderRadius.circular(4),
                        border: pw.Border.all(color: const PdfColor.fromInt(0xFF334155), width: 0.5),
                      ),
                      child: pw.Text(
                        '${match.format.toUpperCase()} | ${match.totalOvers} OVERS',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  match.title,
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 15,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Row(
                  children: [
                    _venuePinIcon(),
                    pw.SizedBox(width: 4),
                    pw.Text(
                      match.venue,
                      style: const pw.TextStyle(color: PdfColors.white, fontSize: 8.5),
                    ),
                    pw.SizedBox(width: 14),
                    _calendarIcon(),
                    pw.SizedBox(width: 4),
                    pw.Text(
                      DateFormatter.formatDate(DateTime.fromMillisecondsSinceEpoch(match.matchDate)),
                      style: const pw.TextStyle(color: PdfColors.white, fontSize: 8.5),
                    ),
                    if (tossTeam != null) ...[
                      pw.SizedBox(width: 14),
                      _coinIcon(),
                      pw.SizedBox(width: 4),
                      pw.Text(
                        'Toss: $tossTeam won & elected to ${match.tossDecision ?? 'bat'}',
                        style: const pw.TextStyle(color: PdfColors.white, fontSize: 8.5),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. Match Result Banner (Themed to Winner's Team Color)
  // ---------------------------------------------------------------------------
  static pw.Widget _buildResultBanner(
    CricketMatch match,
    Team teamA,
    Team teamB,
    PdfColor teamAColor,
    PdfColor teamBColor,
  ) {
    final hasResult = match.resultSummary != null && match.resultSummary!.isNotEmpty;

    if (hasResult) {
      PdfColor resultColor = _emerald;
      if (match.winnerTeamId == teamA.id) {
        resultColor = teamAColor;
      } else if (match.winnerTeamId == teamB.id) {
        resultColor = teamBColor;
      } else if (match.resultSummary!.toLowerCase().contains('tie')) {
        resultColor = _gold;
      }

      final bgColor = _tintColor(resultColor, 0.10);

      return pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.symmetric(vertical: 7, horizontal: 12),
        decoration: pw.BoxDecoration(
          color: bgColor,
          border: pw.Border.all(color: resultColor, width: 1.2),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Row(
          children: [
            _trophyIcon(color: resultColor, size: 14),
            pw.SizedBox(width: 6),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: pw.BoxDecoration(
                color: resultColor,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(
                'RESULT',
                style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Expanded(
              child: pw.Text(
                match.resultSummary!,
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: _navyDark,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: pw.BoxDecoration(
        color: _tableHeaderBg,
        border: pw.Border.all(color: _borderColor, width: 1),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        children: [
          pw.Text(
            'MATCH STATUS: ',
            style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: _textMuted),
          ),
          pw.Text(
            match.status.toUpperCase(),
            style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: _navySlate),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Teams Overview Card (Each styled with its own Team Color)
  // ---------------------------------------------------------------------------
  static pw.Widget _buildTeamsCard(
    CricketMatch match,
    Team teamA,
    Team teamB,
    PdfColor teamAColor,
    PdfColor teamBColor,
  ) {
    return pw.Row(
      children: [
        pw.Expanded(child: _buildSingleTeamBox(teamA, teamColor: teamAColor)),
        pw.SizedBox(width: 10),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: pw.BoxDecoration(
            color: _tableHeaderBg,
            borderRadius: pw.BorderRadius.circular(4),
            border: pw.Border.all(color: _borderColor, width: 0.5),
          ),
          child: pw.Text('VS', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: _textMuted)),
        ),
        pw.SizedBox(width: 10),
        pw.Expanded(child: _buildSingleTeamBox(teamB, teamColor: teamBColor)),
      ],
    );
  }

  static pw.Widget _buildSingleTeamBox(Team team, {required PdfColor teamColor}) {
    final bgTint = _tintColor(teamColor, 0.06);

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: pw.BoxDecoration(
        color: bgTint,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: _tintColor(teamColor, 0.25), width: 0.8),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            width: 3.5,
            height: 24,
            decoration: pw.BoxDecoration(
              color: teamColor,
              borderRadius: pw.BorderRadius.circular(1.5),
            ),
          ),
          pw.SizedBox(width: 7),
          pw.Container(
            width: 22,
            height: 22,
            alignment: pw.Alignment.center,
            decoration: pw.BoxDecoration(
              color: teamColor,
              shape: pw.BoxShape.circle,
            ),
            child: pw.Text(
              team.shortName.isNotEmpty ? team.shortName.substring(0, 1) : 'T',
              style: pw.TextStyle(color: PdfColors.white, fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  team.name,
                  style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: _navyDark),
                  maxLines: 1,
                ),
                if (team.shortName.isNotEmpty)
                  pw.Text(
                    '(${team.shortName})',
                    style: const pw.TextStyle(fontSize: 7.5, color: _textMuted),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. Full Innings Section (Themed with Batting Team's Color)
  // ---------------------------------------------------------------------------
  static pw.Widget _buildInningsSection({
    required Innings inn,
    required CricketMatch match,
    required Team teamA,
    required Team teamB,
    required PdfColor teamAColor,
    required PdfColor teamBColor,
    required List<BattingStat> battingStats,
    required List<BowlingStat> bowlingStats,
    required List<FallOfWicket> fallOfWickets,
    required List<Partnership> partnerships,
    required List<OverSummary> overSummaries,
  }) {
    final isBattingTeamA = inn.battingTeamId == teamA.id;
    final battingTeamName = isBattingTeamA ? teamA.name : teamB.name;
    final battingTeamColor = isBattingTeamA ? teamAColor : teamBColor;
    final bowlingTeamColor = isBattingTeamA ? teamBColor : teamAColor;

    final total4s = battingStats.fold<int>(0, (sum, b) => sum + b.fours);
    final total6s = battingStats.fold<int>(0, (sum, b) => sum + b.sixes);
    final boundaryRuns = (total4s * 4) + (total6s * 6);
    final boundaryPct = inn.totalRuns > 0 ? ((boundaryRuns / inn.totalRuns) * 100).toStringAsFixed(0) : '0';

    final battingTableHeadBg = _tintColor(battingTeamColor, 0.12);
    final bowlingTableHeadBg = _tintColor(bowlingTeamColor, 0.12);

    return pw.Container(
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: _borderColor, width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Innings Top Header Bar - Solid Batting Team's Color
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 7, horizontal: 12),
            decoration: pw.BoxDecoration(
              color: battingTeamColor,
              borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(5),
                topRight: pw.Radius.circular(5),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Row(
                  children: [
                    _cricketBatBallIcon(color: PdfColors.white, size: 11),
                    pw.SizedBox(width: 6),
                    pw.Text(
                      '${inn.inningsNumber == 1 ? "1st" : "2nd"} Innings - $battingTeamName',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10.5, color: PdfColors.white),
                    ),
                  ],
                ),
                pw.Text(
                  '${inn.totalRuns}/${inn.totalWickets} (${inn.oversDisplay} Ov | CRR: ${inn.currentRunRate.toStringAsFixed(2)})',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10.5, color: PdfColors.white),
                ),
              ],
            ),
          ),

          pw.Padding(
            padding: const pw.EdgeInsets.all(10),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // 4A. BATTING TABLE
                _buildSectionTitle(
                  'BATTING',
                  icon: _batIcon(color: battingTeamColor),
                  accentColor: battingTeamColor,
                ),
                pw.SizedBox(height: 4),
                pw.Table(
                  border: pw.TableBorder.all(color: _borderColor, width: 0.5),
                  children: [
                    // Batting Header Row (Themed with Batting Team's Accent Tint)
                    pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: battingTableHeadBg,
                        border: pw.Border(bottom: pw.BorderSide(color: battingTeamColor, width: 1)),
                      ),
                      children: [
                        _tableHeaderCell('Batter', flex: 4),
                        _tableHeaderCell('Dismissal', flex: 4),
                        _tableHeaderCell('R', align: pw.TextAlign.right, flex: 1),
                        _tableHeaderCell('B', align: pw.TextAlign.right, flex: 1),
                        _tableHeaderCell('4s', align: pw.TextAlign.right, textColor: _blue4s, flex: 1),
                        _tableHeaderCell('6s', align: pw.TextAlign.right, textColor: _purple6s, flex: 1),
                        _tableHeaderCell('SR', align: pw.TextAlign.right, flex: 1),
                      ],
                    ),
                    // Batter Rows
                    for (int bi = 0; bi < battingStats.length; bi++) ...[
                      pw.TableRow(
                        decoration: pw.BoxDecoration(
                          color: bi % 2 == 1 ? _tableAltBg : PdfColors.white,
                        ),
                        children: [
                          _tableBodyCell(
                            battingStats[bi].playerName,
                            flex: 4,
                            isBold: !battingStats[bi].isOut,
                          ),
                          _tableBodyCell(
                            battingStats[bi].dismissalSummary,
                            flex: 4,
                            isMuted: battingStats[bi].isOut,
                            textColor: !battingStats[bi].isOut ? _emerald : null,
                            isBold: !battingStats[bi].isOut,
                          ),
                          _tableBodyCell(
                            '${battingStats[bi].runs}',
                            align: pw.TextAlign.right,
                            isBold: true,
                            flex: 1,
                          ),
                          _tableBodyCell(
                            '${battingStats[bi].balls}',
                            align: pw.TextAlign.right,
                            flex: 1,
                          ),
                          _tableBodyCell(
                            '${battingStats[bi].fours}',
                            align: pw.TextAlign.right,
                            textColor: battingStats[bi].fours > 0 ? _blue4s : null,
                            isBold: battingStats[bi].fours > 0,
                            flex: 1,
                          ),
                          _tableBodyCell(
                            '${battingStats[bi].sixes}',
                            align: pw.TextAlign.right,
                            textColor: battingStats[bi].sixes > 0 ? _purple6s : null,
                            isBold: battingStats[bi].sixes > 0,
                            flex: 1,
                          ),
                          _tableBodyCell(
                            battingStats[bi].strikeRate.toStringAsFixed(1),
                            align: pw.TextAlign.right,
                            flex: 1,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),

                // Innings Extras & Totals Bar
                pw.SizedBox(height: 5),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                  decoration: pw.BoxDecoration(
                    color: _tintColor(battingTeamColor, 0.08),
                    borderRadius: pw.BorderRadius.circular(4),
                    border: pw.Border.all(color: _tintColor(battingTeamColor, 0.25), width: 0.6),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Extras: ${inn.totalExtras} (wd ${inn.wides}, nb ${inn.noBalls}, b ${inn.byes}, lb ${inn.legByes}${inn.penaltyRuns > 0 ? ", pen ${inn.penaltyRuns}" : ""})',
                        style: const pw.TextStyle(fontSize: 8, color: _navySlate),
                      ),
                      pw.Text(
                        'TOTAL: ${inn.totalRuns}/${inn.totalWickets} (${inn.oversDisplay} Ov, RR: ${inn.currentRunRate.toStringAsFixed(2)})',
                        style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: _navyDark),
                      ),
                    ],
                  ),
                ),

                // Boundary Statistics Strip
                pw.SizedBox(height: 4),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 8),
                  decoration: pw.BoxDecoration(
                    color: _tableAltBg,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Fours: $total4s (${total4s * 4} runs)', style: pw.TextStyle(fontSize: 7.5, color: _blue4s, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Sixes: $total6s (${total6s * 6} runs)', style: pw.TextStyle(fontSize: 7.5, color: _purple6s, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Boundaries: $boundaryRuns runs ($boundaryPct%)', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: _navySlate)),
                    ],
                  ),
                ),

                // 4B. FALL OF WICKETS
                if (fallOfWickets.isNotEmpty) ...[
                  pw.SizedBox(height: 10),
                  _buildSectionTitle(
                    'FALL OF WICKETS',
                    icon: _stumpsIcon(color: battingTeamColor),
                    accentColor: battingTeamColor,
                  ),
                  pw.SizedBox(height: 4),
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(6),
                    decoration: pw.BoxDecoration(
                      color: _tintColor(battingTeamColor, 0.05),
                      borderRadius: pw.BorderRadius.circular(4),
                      border: pw.Border.all(color: _tintColor(battingTeamColor, 0.20), width: 0.5),
                    ),
                    child: pw.Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: fallOfWickets.map((fow) {
                        return pw.Text(
                          '${fow.wicketNumber}-${fow.score} (${fow.playerName}, ${fow.overDisplay} ov)',
                          style: const pw.TextStyle(fontSize: 7.5, color: _navySlate),
                        );
                      }).toList(),
                    ),
                  ),
                ],

                // 4C. KEY PARTNERSHIPS
                if (partnerships.isNotEmpty) ...[
                  pw.SizedBox(height: 8),
                  _buildSectionTitle(
                    'KEY PARTNERSHIPS',
                    icon: _partnershipIcon(color: battingTeamColor),
                    accentColor: battingTeamColor,
                  ),
                  pw.SizedBox(height: 4),
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(6),
                    decoration: pw.BoxDecoration(
                      color: _tintColor(battingTeamColor, 0.05),
                      borderRadius: pw.BorderRadius.circular(4),
                      border: pw.Border.all(color: _tintColor(battingTeamColor, 0.20), width: 0.5),
                    ),
                    child: pw.Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: partnerships.map((part) {
                        return pw.Text(
                          'Wkt ${part.wicketNumber}: ${part.totalRuns}r (${part.totalBalls}b) - ${part.batter1Name} & ${part.batter2Name}',
                          style: const pw.TextStyle(fontSize: 7.5, color: _navySlate),
                        );
                      }).toList(),
                    ),
                  ),
                ],

                // 4D. BOWLING TABLE (Themed with Bowling Team's Accent)
                pw.SizedBox(height: 10),
                _buildSectionTitle(
                  'BOWLING',
                  icon: _ballIcon(color: bowlingTeamColor),
                  accentColor: bowlingTeamColor,
                ),
                pw.SizedBox(height: 4),
                pw.Table(
                  border: pw.TableBorder.all(color: _borderColor, width: 0.5),
                  children: [
                    // Header Row (Themed with Bowling Team's Accent Tint)
                    pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: bowlingTableHeadBg,
                        border: pw.Border(bottom: pw.BorderSide(color: bowlingTeamColor, width: 1)),
                      ),
                      children: [
                        _tableHeaderCell('Bowler', flex: 4),
                        _tableHeaderCell('O', align: pw.TextAlign.right, flex: 1),
                        _tableHeaderCell('M', align: pw.TextAlign.right, flex: 1),
                        _tableHeaderCell('R', align: pw.TextAlign.right, flex: 1),
                        _tableHeaderCell('W', align: pw.TextAlign.right, textColor: _crimson, flex: 1),
                        _tableHeaderCell('ECON', align: pw.TextAlign.right, flex: 1),
                        _tableHeaderCell('0s', align: pw.TextAlign.right, flex: 1),
                        _tableHeaderCell('WD', align: pw.TextAlign.right, flex: 1),
                        _tableHeaderCell('NB', align: pw.TextAlign.right, flex: 1),
                      ],
                    ),
                    // Bowler Rows
                    for (int bwi = 0; bwi < bowlingStats.length; bwi++) ...[
                      pw.TableRow(
                        decoration: pw.BoxDecoration(
                          color: bwi % 2 == 1 ? _tableAltBg : PdfColors.white,
                        ),
                        children: [
                          _tableBodyCell(bowlingStats[bwi].playerName, flex: 4),
                          _tableBodyCell(bowlingStats[bwi].oversDisplay, align: pw.TextAlign.right, flex: 1),
                          _tableBodyCell('${bowlingStats[bwi].maidens}', align: pw.TextAlign.right, flex: 1),
                          _tableBodyCell('${bowlingStats[bwi].runsConceded}', align: pw.TextAlign.right, flex: 1),
                          _tableBodyCell(
                            '${bowlingStats[bwi].wickets}',
                            align: pw.TextAlign.right,
                            isBold: true,
                            textColor: bowlingStats[bwi].wickets > 0 ? _crimson : null,
                            flex: 1,
                          ),
                          _tableBodyCell(bowlingStats[bwi].economy.toStringAsFixed(2), align: pw.TextAlign.right, flex: 1),
                          _tableBodyCell('${bowlingStats[bwi].dots}', align: pw.TextAlign.right, flex: 1),
                          _tableBodyCell('${bowlingStats[bwi].wides}', align: pw.TextAlign.right, flex: 1),
                          _tableBodyCell('${bowlingStats[bwi].noBalls}', align: pw.TextAlign.right, flex: 1),
                        ],
                      ),
                    ],
                  ],
                ),

                // 4E. OVER-BY-OVER SUMMARY
                if (overSummaries.isNotEmpty) ...[
                  pw.SizedBox(height: 10),
                  _buildSectionTitle(
                    'OVER-BY-OVER DETAILS',
                    icon: _sequenceIcon(color: bowlingTeamColor),
                    accentColor: bowlingTeamColor,
                  ),
                  pw.SizedBox(height: 4),
                  _buildOverSummariesTable(overSummaries, headBg: _tintColor(bowlingTeamColor, 0.10)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Over Summaries Table Helper
  // ---------------------------------------------------------------------------
  static pw.Widget _buildOverSummariesTable(List<OverSummary> overSummaries, {required PdfColor headBg}) {
    int runningScore = 0;
    int runningWickets = 0;

    return pw.Table(
      border: pw.TableBorder.all(color: _borderColor, width: 0.5),
      children: [
        // Header
        pw.TableRow(
          decoration: pw.BoxDecoration(color: headBg),
          children: [
            _tableHeaderCell('Over', flex: 1),
            _tableHeaderCell('Bowler', flex: 3),
            _tableHeaderCell('Ball Sequence', flex: 4),
            _tableHeaderCell('Runs', align: pw.TextAlign.right, flex: 1),
            _tableHeaderCell('Wkts', align: pw.TextAlign.right, flex: 1),
            _tableHeaderCell('Score', align: pw.TextAlign.right, flex: 2),
          ],
        ),
        // Rows
        for (int i = 0; i < overSummaries.length; i++) ...[
          () {
            final over = overSummaries[i];
            runningScore += over.runs;
            runningWickets += over.wickets;
            final ballTokens = over.balls.map(_formatBallToken).join('  ');

            return pw.TableRow(
              decoration: pw.BoxDecoration(
                color: i % 2 == 1 ? _tableAltBg : PdfColors.white,
              ),
              children: [
                _tableBodyCell('Ov ${over.overNumber + 1}', flex: 1, isBold: true),
                _tableBodyCell(over.bowlerName, flex: 3),
                _tableBodyCell(ballTokens, flex: 4),
                _tableBodyCell('${over.runs}', align: pw.TextAlign.right, flex: 1),
                _tableBodyCell(
                  over.wickets > 0 ? '${over.wickets}' : '-',
                  align: pw.TextAlign.right,
                  textColor: over.wickets > 0 ? _crimson : null,
                  isBold: over.wickets > 0,
                  flex: 1,
                ),
                _tableBodyCell('$runningScore/$runningWickets', align: pw.TextAlign.right, isBold: true, flex: 2),
              ],
            );
          }(),
        ],
      ],
    );
  }

  /// Format ball-by-ball tokens with pure ASCII characters
  /// that print 100% reliably on all PDF printers (no unprintable emojis or bullets)
  static String _formatBallToken(Ball b) {
    if (b.isWicket) return 'W';
    if (b.extraType == 'wide') return b.extras > 1 ? '${b.extras}wd' : 'wd';
    if (b.extraType == 'noball') return b.extras > 1 ? '${b.extras}nb' : 'nb';
    if (b.extraType == 'bye') return '${b.extras}b';
    if (b.extraType == 'legbye') return '${b.extras}lb';
    if (b.extraType == 'penalty') return '${b.extras}p';
    if (b.runsBat == 0) return '.';
    return '${b.runsBat}';
  }

  // ---------------------------------------------------------------------------
  // Helper Widgets: Section Titles & Table Cells
  // ---------------------------------------------------------------------------
  static pw.Widget _buildSectionTitle(String title, {pw.Widget? icon, PdfColor? accentColor}) {
    return pw.Row(
      children: [
        if (icon != null) ...[
          icon,
          pw.SizedBox(width: 5),
        ] else ...[
          pw.Container(
            width: 3.5,
            height: 10,
            decoration: pw.BoxDecoration(
              color: accentColor ?? _crimson,
              borderRadius: pw.BorderRadius.circular(1),
            ),
            margin: const pw.EdgeInsets.only(right: 5),
          ),
        ],
        pw.Text(
          title,
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 8.5,
            color: _navySlate,
            letterSpacing: 0.5,
          ),
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
          fontSize: 7.5,
          fontWeight: pw.FontWeight.bold,
          color: textColor ?? _navyDark,
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
          fontSize: 7.5,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: textColor ?? (isMuted ? _textMuted : _navyDark),
        ),
      ),
    );
  }
}
