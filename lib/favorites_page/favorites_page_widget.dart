import '/components/button/button_widget.dart';
import '/flutter_flow/ff_builtin_enums.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'favorites_page_model.dart';
export 'favorites_page_model.dart';

/// DSL page FavoritesPage
class FavoritesPageWidget extends StatefulWidget {
  const FavoritesPageWidget({super.key});

  static String routeName = 'FavoritesPage';
  static String routePath = '/favorites';

  @override
  State<FavoritesPageWidget> createState() => _FavoritesPageWidgetState();
}

class _FavoritesPageWidgetState extends State<FavoritesPageWidget> {
  late FavoritesPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => FavoritesPageModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    context.watch<FFAppState>();

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: theme.background,
        appBar: AppBar(
          backgroundColor: theme.background,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: true,
          title: Text(
            'المفضلة',
            style: theme.titleLarge.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: theme.primaryText,
            ),
          ),
          actions: const [],
          centerTitle: true,
          elevation: 0,
        ),
        body: SafeArea(
          top: true,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الأماكن المحفوظة على هذا الجهاز',
                    style: theme.bodyMedium.copyWith(
                      fontSize: 14,
                      color: theme.secondaryText,
                    ),
                  ),
                  if (FFAppState().favoritePlaceIds.isEmpty) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: theme.surface,
                        borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
                        border: Border.all(color: theme.outlineVariant, width: 1.5),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.favorite_border_rounded,
                            size: 48,
                            color: theme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'لا توجد أماكن في المفضلة',
                            style: theme.titleMedium.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: theme.primaryText,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'افتح تفاصيل مكان واضغط على القلب لإضافته للمفضلة.',
                            style: theme.bodyMedium.copyWith(
                              fontSize: 14,
                              color: theme.secondaryText,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ]
                  else
                    Builder(
                      builder: (context) {
                        final placeId = FFAppState().favoritePlaceIds.toList();

                        return ListView.separated(
                          padding: EdgeInsets.zero,
                          primary: false,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: placeId.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, placeIdIndex) {
                            final placeIdItem = placeId[placeIdIndex];
                            return _FavoritePlaceItem(
                              placeId: placeIdItem,
                              theme: theme,
                            );
                          },
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FavoritePlaceItem extends StatelessWidget {
  const _FavoritePlaceItem({
    required this.placeId,
    required this.theme,
  });

  final String placeId;
  final FlutterFlowTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
        border: Border.all(color: theme.outlineVariant, width: 1.5),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(theme.designToken.radius.lg),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.place_rounded,
              color: theme.secondary,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              placeId,
              style: theme.titleMedium.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: theme.primaryText,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ButtonWidget(
            content: 'إزالة',
            variant: 'ghost',
            size: 'small',
            onPressed: () {
              FFAppState().removeFromFavoritePlaceIds(placeId);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('أزيل المكان من المفضلة على هذا الجهاز.'),
                  duration: Duration(milliseconds: 4000),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}