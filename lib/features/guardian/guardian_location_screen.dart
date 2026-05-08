import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/design_tokens.dart';
import '../../core/theme.dart';
import '../../services/realtime_service.dart';

class GuardianLocationScreen extends ConsumerStatefulWidget {
  final String seniorId;
  const GuardianLocationScreen({super.key, required this.seniorId});

  @override
  ConsumerState<GuardianLocationScreen> createState() =>
      _GuardianLocationScreenState();
}

class _GuardianLocationScreenState
    extends ConsumerState<GuardianLocationScreen> {
  GoogleMapController? _ctrl;

  String _agoText(DateTime? at) {
    if (at == null) return '아직 위치 정보가 없습니다';
    final diff = DateTime.now().difference(at);
    if (diff.inMinutes < 1) return '마지막 업데이트: 방금 전';
    if (diff.inMinutes < 60) return '마지막 업데이트: ${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '마지막 업데이트: ${diff.inHours}시간 전';
    return '마지막 업데이트: ${diff.inDays}일 전';
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync =
        ref.watch(remoteSeniorSettingsProvider(widget.seniorId));
    return Theme(
      data: JTheme.guardian(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: JD.gInk),
                    ),
                    const Text(
                      '부모님 위치',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: JD.gInk,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () =>
                          ref.invalidate(remoteSeniorSettingsProvider(
                              widget.seniorId)),
                      icon: const Icon(Icons.refresh_rounded,
                          color: JD.gBlue),
                      tooltip: '새로고침',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: settingsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) => const Center(
                      child: Text('지도를 불러오지 못했습니다')),
                  data: (s) {
                    final lat = s.latitude;
                    final lng = s.longitude;
                    if (lat == null || lng == null) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text(
                            '아직 위치 정보가 없어요.\n잠시 후 다시 확인해주세요',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: JD.gInkSoft,
                              height: 1.5,
                            ),
                          ),
                        ),
                      );
                    }
                    final pos = LatLng(lat, lng);
                    return Stack(
                      children: [
                        _SafeMap(
                          target: pos,
                          markers: {
                            Marker(
                              markerId: const MarkerId('senior'),
                              position: pos,
                              infoWindow: const InfoWindow(title: '부모님'),
                            ),
                          },
                          onCreated: (c) => _ctrl = c,
                        ),
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: JD.shadowBlueCard,
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.place_rounded,
                                    color: JD.gBlue, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _agoText(s.locationUpdatedAt),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: JD.gInk,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }
}

/// Google Maps API 키가 없거나 로드 실패 시 회색 placeholder 로 폴백.
class _SafeMap extends StatefulWidget {
  final LatLng target;
  final Set<Marker> markers;
  final void Function(GoogleMapController) onCreated;
  const _SafeMap({
    required this.target,
    required this.markers,
    required this.onCreated,
  });

  @override
  State<_SafeMap> createState() => _SafeMapState();
}

class _SafeMapState extends State<_SafeMap> {
  bool _failed = false;

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return Container(
        color: const Color(0xFFEEF1F6),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              '지도를 표시할 수 없습니다.\n(Google Maps API 키 필요)',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: JD.gInkSoft,
                height: 1.5,
              ),
            ),
          ),
        ),
      );
    }
    try {
      return GoogleMap(
        initialCameraPosition: CameraPosition(target: widget.target, zoom: 16),
        markers: widget.markers,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: true,
        onMapCreated: widget.onCreated,
      );
    } catch (_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _failed = true);
      });
      return const SizedBox.shrink();
    }
  }
}
