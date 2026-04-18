import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../models/blood_requirement.dart';
import '../../utils/app_theme.dart';
import '../../viewmodels/requirements_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'dart:ui' as ui;

/// Map view showing blood requests as markers on OpenStreetMap.
class FeedMapView extends ConsumerStatefulWidget {
  const FeedMapView({super.key});

  @override
  ConsumerState<FeedMapView> createState() => _FeedMapViewState();
}

class _FeedMapViewState extends ConsumerState<FeedMapView> {
  final MapController _mapController = MapController();
  BloodRequirement? _selectedRequest;

  @override
  Widget build(BuildContext context) {
    final reqState = ref.watch(requirementsViewModelProvider);
    final userLoc = reqState.userLocation;

    // Filter to only requests that have coordinates
    final mappable = reqState.filtered
        .where((r) => r.latitude != null && r.longitude != null)
        .toList();

    // Determine map center
    LatLng center;
    double zoom;
    if (userLoc != null) {
      center = LatLng(userLoc.latitude, userLoc.longitude);
      zoom = 12.0;
    } else if (mappable.isNotEmpty) {
      center = LatLng(mappable.first.latitude!, mappable.first.longitude!);
      zoom = 12.0;
    } else {
      // Default: Coimbatore
      center = const LatLng(11.0168, 76.9558);
      zoom = 11.0;
    }

    return Stack(
      children: [
        // ── Map ──────────────────────────────────────────────────
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: zoom,
            minZoom: 5,
            maxZoom: 18,
            onTap: (_, __) => setState(() => _selectedRequest = null),
          ),
          children: [
            // OSM tile layer
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.hsblood.bloodconnect',
              maxZoom: 19,
            ),

            // User location marker
            if (userLoc != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(userLoc.latitude, userLoc.longitude),
                    width: 28,
                    height: 28,
                    child: _UserLocationDot(),
                  ),
                ],
              ),

            // Blood request markers
            MarkerLayer(
              markers: mappable.map((req) {
                final isSelected = _selectedRequest?.id == req.id;
                return Marker(
                  point: LatLng(req.latitude!, req.longitude!),
                  width: isSelected ? 48 : 40,
                  height: isSelected ? 56 : 48,
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedRequest = req),
                    child: _BloodRequestMarker(
                      requirement: req,
                      isSelected: isSelected,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),

        // ── Request count badge ──────────────────────────────────
        Positioned(
          top: 12,
          left: 14,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.bloodtype_outlined, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                '${mappable.length} on map',
                style: GoogleFonts.syne(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (reqState.filtered.length > mappable.length) ...[
                const SizedBox(width: 4),
                Text(
                  '(${reqState.filtered.length - mappable.length} without location)',
                  style: GoogleFonts.dmSans(
                    fontSize: 9,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ]),
          ),
        ),

        // ── Re-center button ─────────────────────────────────────
        if (userLoc != null)
          Positioned(
            top: 12,
            right: 14,
            child: GestureDetector(
              onTap: () => _mapController.move(
                LatLng(userLoc.latitude, userLoc.longitude), 13,
              ),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.my_location_rounded,
                    size: 18, color: AppColors.primary),
              ),
            ),
          ),

        // ── Selected request card (bottom sheet style) ───────────
        if (_selectedRequest != null)
          Positioned(
            left: 14,
            right: 14,
            bottom: 14,
            child: _MapRequestCard(
              requirement: _selectedRequest!,
              onClose: () => setState(() => _selectedRequest = null),
              onTap: () {
                context.push(
                  '/requirement/${_selectedRequest!.id}',
                  extra: {'requirement': _selectedRequest!},
                );
              },
            ),
          ),

        // ── Empty state overlay ──────────────────────────────────
        if (mappable.isEmpty && !reqState.isLoading)
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.95),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.map_outlined, size: 36, color: AppColors.textMuted),
                const SizedBox(height: 12),
                Text(
                  'No requests on map',
                  style: GoogleFonts.syne(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Requests without location data won\'t appear on the map. Switch to list view to see all.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ]),
            ),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  MARKER WIDGETS
// ═══════════════════════════════════════════════════════════════

/// Blue pulsing dot for user's current location.
class _UserLocationDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF2196F3).withOpacity(0.15),
        border: Border.all(color: const Color(0xFF2196F3).withOpacity(0.3), width: 2),
      ),
      child: Center(
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF2196F3),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2196F3).withOpacity(0.4),
                blurRadius: 6,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Blood drop marker for a request on the map.
class _BloodRequestMarker extends StatelessWidget {
  final BloodRequirement requirement;
  final bool isSelected;

  const _BloodRequestMarker({
    required this.requirement,
    this.isSelected = false,
  });

  Color get _markerColor {
    if (requirement.isFulfilled) return AppColors.secondary;
    if (requirement.isCancelled) return AppColors.textMuted;
    switch (requirement.urgency) {
      case 'Critical': return AppColors.primary;
      case 'High':     return const Color(0xFFE85D2F);
      case 'Medium':   return const Color(0xFFF5A623);
      case 'Low':      return const Color(0xFF1D9E75);
      default:         return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _markerColor;

    return AnimatedScale(
      scale: isSelected ? 1.15 : 1.0,
      duration: const Duration(milliseconds: 150),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isSelected ? 40 : 34,
            height: isSelected ? 40 : 34,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(isSelected ? 12 : 10),
              border: Border.all(
                color: Colors.white,
                width: isSelected ? 3 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: isSelected ? 10 : 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Text(
                requirement.bloodType,
                style: GoogleFonts.syne(
                  fontSize: isSelected ? 10 : 9,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          // Arrow pointing down
          CustomPaint(
            size: const Size(12, 7),
            painter: _MarkerArrowPainter(color: color),
          ),
        ],
      ),
    );
  }
}

/// Paints the downward triangle/arrow under the marker.
class _MarkerArrowPainter extends CustomPainter {
  final Color color;
  _MarkerArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = ui.Path()   // was: Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════
//  SELECTED REQUEST CARD (bottom overlay)
// ═══════════════════════════════════════════════════════════════

class _MapRequestCard extends ConsumerWidget {
  final BloodRequirement requirement;
  final VoidCallback onClose;
  final VoidCallback onTap;

  const _MapRequestCard({
    required this.requirement,
    required this.onClose,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reqState = ref.watch(requirementsViewModelProvider);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                // Blood type badge
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _urgencyColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _urgencyColor.withOpacity(0.3)),
                  ),
                  child: Center(
                    child: Text(
                      requirement.bloodType,
                      style: GoogleFonts.syne(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _urgencyColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Hospital + location
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        requirement.hospital,
                        style: GoogleFonts.syne(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(children: [
                        if (requirement.location.isNotEmpty) ...[
                          const Icon(Icons.location_on_outlined,
                              size: 11, color: AppColors.primary),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              requirement.location,
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        if (requirement.distanceKm != null &&
                            reqState.hasGpsLocation) ...[
                          if (requirement.location.isNotEmpty)
                            const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              requirement.distanceDisplay!,
                              style: GoogleFonts.dmSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ]),
                    ],
                  ),
                ),
                // Close button
                GestureDetector(
                  onTap: onClose,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.border.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.close_rounded,
                        size: 14, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Info row
            Row(children: [
              _InfoTag(
                icon: Icons.water_drop_outlined,
                label:
                    '${requirement.remainingUnits} unit${requirement.remainingUnits != 1 ? 's' : ''} needed',
              ),
              const SizedBox(width: 8),
              _InfoTag(
                icon: Icons.warning_amber_rounded,
                label: requirement.urgency,
                color: _urgencyColor,
              ),
              const Spacer(),
              Icon(Icons.chevron_right_rounded,
                  size: 18, color: AppColors.textMuted),
            ]),
          ],
        ),
      ),
    );
  }

  Color get _urgencyColor {
    switch (requirement.urgency) {
      case 'Critical': return AppColors.primary;
      case 'High':     return const Color(0xFFE85D2F);
      case 'Medium':   return const Color(0xFFF5A623);
      case 'Low':      return const Color(0xFF1D9E75);
      default:         return AppColors.primary;
    }
  }
}

class _InfoTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _InfoTag({
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: c),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: c,
          ),
        ),
      ]),
    );
  }
}
