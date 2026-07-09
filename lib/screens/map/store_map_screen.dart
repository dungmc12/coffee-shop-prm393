import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_theme.dart';

/// Màn hình Bản đồ cửa hàng (Thành viên 3).
/// - Hiển thị các cửa hàng trên bản đồ thật (flutter_map + OpenStreetMap).
/// - Bấm vào cửa hàng để di chuyển bản đồ tới đó.
/// - Nút "Chỉ đường" mở Google Maps dẫn đường từ vị trí của bạn.
class StoreMapScreen extends StatefulWidget {
  const StoreMapScreen({super.key});

  @override
  State<StoreMapScreen> createState() => _StoreMapScreenState();
}

class _StoreMapScreenState extends State<StoreMapScreen> {
  // Bộ điều khiển để di chuyển camera bản đồ bằng code.
  final MapController _mapController = MapController();
  int _selected = 0; // cửa hàng đang chọn

  // Danh sách cửa hàng mẫu (tọa độ thật ở TP.HCM).
  static final List<_Store> _stores = [
    _Store('Coffee Shop - Quận 1', const LatLng(10.7769, 106.7009), '12 Nguyễn Huệ, Q1'),
    _Store('Coffee Shop - Thủ Đức', const LatLng(10.8411, 106.8098), 'KCNC, TP. Thủ Đức'),
    _Store('Coffee Shop - Quận 7', const LatLng(10.7340, 106.7215), 'Phú Mỹ Hưng, Q7'),
  ];

  /// Chọn 1 cửa hàng -> di chuyển bản đồ tới vị trí đó.
  void _selectStore(int index) {
    setState(() => _selected = index);
    _mapController.move(_stores[index].position, 15);
  }

  /// Mở Google Maps để chỉ đường tới cửa hàng đang chọn.
  Future<void> _openDirections(_Store store) async {
    final lat = store.position.latitude;
    final lng = store.position.longitude;
    // Link chuẩn của Google Maps: tự dẫn đường từ vị trí hiện tại tới đích.
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không mở được ứng dụng bản đồ')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = _stores[_selected];

    return Scaffold(
      appBar: AppBar(title: const Text('Cửa hàng của chúng tôi')),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _stores.first.position,
                    initialZoom: 12,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.coffee_shop',
                    ),
                    MarkerLayer(
                      markers: List.generate(_stores.length, (i) {
                        final selected = i == _selected;
                        return Marker(
                          point: _stores[i].position,
                          width: 50,
                          height: 50,
                          child: GestureDetector(
                            onTap: () => _selectStore(i),
                            child: Icon(
                              Iconsax.location,
                              color: selected ? AppTheme.primary : AppTheme.danger,
                              size: selected ? 44 : 36,
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
                // Nút chỉ đường nổi trên bản đồ.
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton.extended(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    onPressed: () => _openDirections(store),
                    icon: const Icon(Iconsax.routing_2),
                    label: const Text('Chỉ đường'),
                  ),
                ),
              ],
            ),
          ),
          // Danh sách cửa hàng phía dưới - bấm để chọn.
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(_stores.length, (i) {
                final s = _stores[i];
                final selected = i == _selected;
                return ListTile(
                  selected: selected,
                  selectedTileColor: AppTheme.accent.withValues(alpha: 0.12),
                  leading: CircleAvatar(
                    backgroundColor: selected ? AppTheme.primary : AppTheme.accent,
                    child: const Icon(Iconsax.shop, color: Colors.white, size: 20),
                  ),
                  title: Text(s.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(s.address),
                  trailing: IconButton(
                    icon: const Icon(Iconsax.routing_2, color: AppTheme.primary),
                    onPressed: () => _openDirections(s),
                  ),
                  onTap: () => _selectStore(i),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lớp dữ liệu đơn giản cho 1 cửa hàng.
class _Store {
  final String name;
  final LatLng position;
  final String address;
  _Store(this.name, this.position, this.address);
}
