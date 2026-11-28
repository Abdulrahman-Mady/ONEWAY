import '/components/accessibility_chip/accessibility_chip_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'place_preview_card_model.dart';
export 'place_preview_card_model.dart';

class PlacePreviewCardWidget extends StatefulWidget {
  const PlacePreviewCardWidget({
    super.key,
    String? category,
    String? distance,
    String? imageDesc,
    String? name,
    String? score,
  })  : category = category ?? '',
        distance = distance ?? '',
        imageDesc = imageDesc ?? '',
        name = name ?? '',
        score = score ?? '';

  final String category;
  final String distance;
  final String imageDesc;
  final String name;
  final String score;

  @override
  State<PlacePreviewCardWidget> createState() => _PlacePreviewCardWidgetState();
}

class _PlacePreviewCardWidgetState extends State<PlacePreviewCardWidget> {
  late PlacePreviewCardModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PlacePreviewCardModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 20.0),
      child: Container(
        child: Container(
          width: 320.0,
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).surface,
            borderRadius: BorderRadius.circular(16.0),
            shape: BoxShape.rectangle,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: Container(
                      width: 80.0,
                      height: 80.0,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.0),
                        shape: BoxShape.rectangle,
                      ),
                      child: widget.imageDesc.trim().isNotEmpty
                          ? CachedNetworkImage(
                              fadeInDuration: const Duration(milliseconds: 0),
                              fadeOutDuration: const Duration(milliseconds: 0),
                              imageUrl: widget.imageDesc,
                              fit: BoxFit.cover,
                              alignment: const Alignment(0.0, 0.0),
                              errorWidget: (_, __, ___) => Icon(
                                Icons.place_outlined,
                                color: FlutterFlowTheme.of(context).primary,
                              ),
                            )
                          : Icon(
                              Icons.place_outlined,
                              color: FlutterFlowTheme.of(context).primary,
                            ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              valueOrDefault<String>(
                                widget.category,
                                'مطاعم',
                              ),
                              style: FlutterFlowTheme.of(context)
                                  .labelSmall
                                  .override(
                                    font: GoogleFonts.cairo(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelSmall
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelSmall
                                          .fontStyle,
                                    ),
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .labelSmall
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .labelSmall
                                        .fontStyle,
                                    lineHeight: 1.2,
                                  ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  color: FlutterFlowTheme.of(context).warning,
                                  size: 14.0,
                                ),
                                Text(
                                  valueOrDefault<String>(
                                    widget.score,
                                    '٤.٨',
                                  ),
                                  style: FlutterFlowTheme.of(context)
                                      .labelSmall
                                      .override(
                                        font: GoogleFonts.cairo(
                                          fontWeight: FontWeight.bold,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .labelSmall
                                                  .fontStyle,
                                        ),
                                        color: FlutterFlowTheme.of(context)
                                            .primaryText,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.bold,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .labelSmall
                                            .fontStyle,
                                        lineHeight: 1.2,
                                      ),
                                ),
                              ].divide(const SizedBox(width: 4.0)),
                            ),
                          ],
                        ),
                        Text(
                          valueOrDefault<String>(
                            widget.name,
                            'مطعم القلعة',
                          ),
                          maxLines: 1,
                          style: FlutterFlowTheme.of(context)
                              .titleSmall
                              .override(
                                font: GoogleFonts.cairo(
                                  fontWeight: FontWeight.bold,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .titleSmall
                                      .fontStyle,
                                ),
                                color: FlutterFlowTheme.of(context).primaryText,
                                letterSpacing: 0.0,
                                fontWeight: FontWeight.bold,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .titleSmall
                                    .fontStyle,
                                lineHeight: 1.4,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              color: FlutterFlowTheme.of(context).secondaryText,
                              size: 14.0,
                            ),
                            Text(
                              valueOrDefault<String>(
                                widget.distance,
                                '٥٠٠ متر',
                              ),
                              style: FlutterFlowTheme.of(context)
                                  .bodySmall
                                  .override(
                                    font: GoogleFonts.cairo(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .bodySmall
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodySmall
                                          .fontStyle,
                                    ),
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryText,
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .bodySmall
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodySmall
                                        .fontStyle,
                                    lineHeight: 1.5,
                                  ),
                            ),
                          ].divide(const SizedBox(width: 4.0)),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            wrapWithModel(
                              model: _model.accessibilityChipModel1,
                              updateCallback: () => safeSetState(() {}),
                              child: AccessibilityChipWidget(
                                icon: Icon(
                                  Icons.wheelchair_pickup_rounded,
                                  color:
                                      FlutterFlowTheme.of(context).primaryText,
                                  size: 14.0,
                                ),
                                label: 'مدخل مجهز',
                                tone: const Color(0x00000000),
                              ),
                            ),
                            wrapWithModel(
                              model: _model.accessibilityChipModel2,
                              updateCallback: () => safeSetState(() {}),
                              child: AccessibilityChipWidget(
                                icon: Icon(
                                  Icons.elevator_rounded,
                                  color:
                                      FlutterFlowTheme.of(context).primaryText,
                                  size: 14.0,
                                ),
                                label: 'مصعد',
                                tone: const Color(0x00000000),
                              ),
                            ),
                          ].divide(const SizedBox(width: 4.0)),
                        ),
                      ].divide(const SizedBox(height: 4.0)),
                    ),
                  ),
                ].divide(const SizedBox(width: 16.0)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
