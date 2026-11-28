import '/auth/firebase_auth/auth_util.dart';
import '/backend/schema/favorites_record.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'place_card_model.dart';
export 'place_card_model.dart';

class PlaceCardWidget extends StatefulWidget {
  const PlaceCardWidget({
    super.key,
    this.placeId,
    String? category,
    String? distance,
    String? imageDesc,
    String? name,
    String? status,
    this.onTap,
    this.accessibilityFeatures,
    this.verificationStatus = 'incomplete',
    this.rating,
    this.reviewCount,
  })  : category = category ?? '',
        distance = distance ?? '',
        imageDesc = imageDesc ?? '',
        name = name ?? '',
        status = status ?? 'قيد المراجعة';

  final String? placeId;
  final String category;
  final String distance;
  final String imageDesc;
  final String name;
  final String status;
  final VoidCallback? onTap;
  final Map<String, dynamic>? accessibilityFeatures;
  final String verificationStatus;
  final double? rating;
  final int? reviewCount;

  @override
  State<PlaceCardWidget> createState() => _PlaceCardWidgetState();
}

class _PlaceCardWidgetState extends State<PlaceCardWidget>
    with SingleTickerProviderStateMixin {
  late PlaceCardModel _model;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PlaceCardModel());
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _elevationAnimation = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _model.maybeDispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _animationController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _animationController.reverse();
    widget.onTap?.call();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  Color _getStatusColor(FlutterFlowTheme theme) {
    switch (widget.verificationStatus) {
      case 'verified':
        return theme.success;
      case 'osmImported':
      case 'googleImported':
      case 'pendingFieldAudit':
      case 'needsUpdate':
        return theme.warning;
      case 'reportUnderReview':
        return theme.info;
      case 'incomplete':
      default:
        return theme.tertiaryText;
    }
  }

  String _getStatusLabel(FlutterFlowTheme theme) {
    switch (widget.verificationStatus) {
      case 'verified':
        return 'تم التحقق ✓';
      case 'pendingFieldAudit':
        return 'بانتظار فحص ميداني';
      case 'needsUpdate':
        return 'يحتاج تحديث';
      case 'reportUnderReview':
        return 'قيد المراجعة';
      case 'incomplete':
      default:
        return widget.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final statusColor = _getStatusColor(theme);

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.translate(
            offset: Offset(0, -_elevationAnimation.value),
            child: child,
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
          splashColor: theme.primary.withValues(alpha: 0.08),
          highlightColor: theme.primary.withValues(alpha: 0.04),
          child: Container(
            width: 280,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
              color: theme.surface,
              boxShadow: [
                theme.designToken.shadow.xs,
                if (_isPressed) theme.designToken.shadow.md,
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image with status badge
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(theme.designToken.radius.xl),
                      ),
                      child: AspectRatio(
                        aspectRatio: 16 / 10,
                        child: CachedNetworkImage(
                          imageUrl: widget.imageDesc,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: theme.surfaceVariant,
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.primary,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: theme.surfaceVariant,
                            child: Icon(
                              Icons.image_not_supported_rounded,
                              color: theme.tertiaryText,
                              size: 48,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Status badge
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: theme.surface,
                          borderRadius: BorderRadius.circular(
                            theme.designToken.radius.full,
                          ),
                          boxShadow: [theme.designToken.shadow.sm],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _getStatusLabel(theme),
                              style: theme.labelSmall.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: theme.primaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Favorite button (rendered only when a valid placeId is provided)
                    if (widget.placeId != null && widget.placeId!.trim().isNotEmpty)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: _FavoriteButton(
                          placeName: widget.name,
                          placeId: widget.placeId!.trim(),
                          placePhoto: widget.imageDesc,
                          placeCategory: widget.category,
                        ),
                      ),
                  ],
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name and category
                      Text(
                        widget.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.titleMedium.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: theme.primaryText,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.category,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.bodySmall.copyWith(
                                fontSize: 12,
                                color: theme.secondaryText,
                                height: 1.3,
                              ),
                            ),
                          ),
                          if (widget.rating != null) ...[
                            Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: Colors.amber.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.rating!.toStringAsFixed(1),
                              style: theme.labelSmall.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: theme.primaryText,
                              ),
                            ),
                            if (widget.reviewCount != null) ...[
                              const SizedBox(width: 2),
                              Text(
                                '(${widget.reviewCount})',
                                style: theme.labelSmall.copyWith(
                                  fontSize: 11,
                                  color: theme.tertiaryText,
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Distance and accessibility badges
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 14,
                            color: theme.tertiaryText,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.distance,
                            style: theme.bodySmall.copyWith(
                              fontSize: 12,
                              color: theme.tertiaryText,
                              height: 1.3,
                            ),
                          ),
                          const Spacer(),
                          // Accessibility indicators
                          if (widget.accessibilityFeatures != null)
                            _buildAccessibilityBadges(theme),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccessibilityBadges(FlutterFlowTheme theme) {
    final features = widget.accessibilityFeatures!;
    final badges = <Widget>[];

    if (features['ramp'] == true) {
      badges.add(_AccessibilityBadge(
        icon: Icons.accessible_forward_rounded,
        label: 'منحدر',
        color: theme.success,
      ));
    }
    if (features['suitableElevator'] == true) {
      badges.add(_AccessibilityBadge(
        icon: Icons.elevator_rounded,
        label: 'مصعد',
        color: theme.info,
      ));
    }
    if (features['accessibleRestroom'] == true) {
      badges.add(_AccessibilityBadge(
        icon: Icons.wc_rounded,
        label: 'حمام',
        color: theme.primary,
      ));
    }
    if (features['wheelchairEntrance'] == true) {
      badges.add(_AccessibilityBadge(
        icon: Icons.wheelchair_pickup_rounded,
        label: 'مدخل',
        color: theme.tertiary,
      ));
    }
    if (features['accessibleParking'] == true) {
      badges.add(_AccessibilityBadge(
        icon: Icons.local_parking_rounded,
        label: 'موقف',
        color: theme.secondary,
      ));
    }

    if (badges.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 24,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: badges
            .expand((badge) => [badge, const SizedBox(width: 6)])
            .toList()
          ..removeLast(),
      ),
    );
  }
}

class _AccessibilityBadge extends StatelessWidget {
  const _AccessibilityBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(theme.designToken.radius.full),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.labelSmall.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoriteButton extends StatefulWidget {
  const _FavoriteButton({
    required this.placeName,
    required this.placeId,
    this.placePhoto = '',
    this.placeCategory = '',
  });

  final String placeName;
  final String placeId;
  final String placePhoto;
  final String placeCategory;

  @override
  State<_FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<_FavoriteButton>
    with SingleTickerProviderStateMixin {
  bool _isFavorite = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _checkFavorite();
  }

  Future<void> _checkFavorite() async {
    final uid = currentUserUid;
    if (uid.isEmpty || widget.placeId.isEmpty) return;
    try {
      final doc =
          await FavoritesRecord.collection.doc('${uid}_${widget.placeId}').get();
      if (mounted) {
        setState(() => _isFavorite = doc.exists);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _toggleFavorite() async {
    final uid = currentUserUid;
    if (uid.isEmpty || currentUserIsAnonymous) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تسجيل الدخول بحساب لحفظ المفضلة.')),
      );
      return;
    }
    final next = !_isFavorite;
    setState(() {
      _isFavorite = next;
      _animationController.forward().then((_) => _animationController.reverse());
    });
    try {
      final docRef = FavoritesRecord.collection.doc('${uid}_${widget.placeId}');
      if (next) {
        await docRef.set({
          'userId': uid,
          'placeId': widget.placeId,
          'placeName': widget.placeName,
          'placePhoto': widget.placePhoto,
          'placeCategory': widget.placeCategory,
          'created_at': FieldValue.serverTimestamp(),
        });
      } else {
        await docRef.delete();
      }
    } catch (_) {}
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          next
              ? 'أضيف "${widget.placeName}" إلى المفضلة'
              : 'أزيل "${widget.placeName}" من المفضلة',
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _toggleFavorite,
          borderRadius: BorderRadius.circular(theme.designToken.radius.full),
          splashColor: theme.error.withValues(alpha: 0.1),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.surface.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(theme.designToken.radius.full),
              boxShadow: [theme.designToken.shadow.sm],
            ),
            child: Icon(
              _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              size: 20,
              color: _isFavorite ? theme.error : theme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}