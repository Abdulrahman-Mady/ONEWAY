import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:math' as math;
import 'package:image/image.dart' as img;

void main() {
  // Create a 1024x1024 base icon
  final int size = 1024;
  final image = img.Image(width: size, height: size);

  // Background gradient (dark navy to slightly lighter)
  for (int y = 0; y < size; y++) {
    for (int x = 0; x < size; x++) {
      final double t = (x + y) / (2 * size);
      final int r = (15 + t * 15).round();
      final int g = (23 + t * 18).round();
      final int b = (42 + t * 15).round();
      image.setPixelRgb(x, y, r, g, b);
    }
  }

  // Draw a circle background
  final centerX = size ~/ 2;
  final centerY = size ~/ 2;
  final radius = (size * 0.45).round();

  // Draw outer ring
  for (int y = 0; y < size; y++) {
    for (int x = 0; x < size; x++) {
      final dx = x - centerX;
      final dy = y - centerY;
      final dist = math.sqrt((dx * dx + dy * dy).toDouble());
      if (dist >= radius - 4 && dist <= radius) {
        // Amber/gold gradient ring
        final double angle = (dx / radius).clamp(-1.0, 1.0);
        final int r = 245;
        final int g = 158 + (angle * 30).round().abs();
        final int b = 11;
        image.setPixelRgb(x, y, r, g, b);
      }
    }
  }

  // Draw wheelchair icon (simplified but recognizable)
  final wheelchairColor = img.ColorRgb8(245, 158, 11); // Amber
  final accentColor = img.ColorRgb8(6, 182, 212); // Cyan

  // Draw wheelchair body using simple shapes
  final wheelRadius = (size * 0.08).round();
  final smallWheelRadius = (size * 0.04).round();
  final seatWidth = (size * 0.18).round();
  final seatHeight = (size * 0.12).round();
  final backHeight = (size * 0.15).round();

  // Rear wheel (large)
  _drawCircle(image, centerX + 80, centerY + 20, wheelRadius, wheelchairColor);
  _drawCircle(image, centerX + 80, centerY + 20, wheelRadius - 8, accentColor);
  _drawCircle(image, centerX + 80, centerY + 20, 12, img.ColorRgb8(15, 23, 42));

  // Front wheel (small)
  _drawCircle(image, centerX - 70, centerY + 70, smallWheelRadius, wheelchairColor);
  _drawCircle(image, centerX - 70, centerY + 70, smallWheelRadius - 4, accentColor);
  _drawCircle(image, centerX - 70, centerY + 70, 6, img.ColorRgb8(15, 23, 42));

  // Seat
  _drawRect(image, centerX - seatWidth ~/ 2, centerY - 40, seatWidth, seatHeight, wheelchairColor);

  // Backrest
  _drawRect(image, centerX - seatWidth ~/ 2 - 10, centerY - 40 - backHeight, seatWidth + 20, backHeight, wheelchairColor);

  // Frame connecting seat to rear wheel
  _drawLine(image, centerX - seatWidth ~/ 2, centerY - 10, centerX + 60, centerY + 20, 6, wheelchairColor);

  // Frame connecting seat to front wheel
  _drawLine(image, centerX - seatWidth ~/ 2, centerY + 30, centerX - 70, centerY + 70, 6, wheelchairColor);

  // Footrest
  _drawLine(image, centerX - seatWidth ~/ 2 - 10, centerY + 30, centerX - seatWidth ~/ 2 - 30, centerY + 70, 5, wheelchairColor);

  // Location pin (top left of wheelchair)
  _drawLocationPin(image, centerX - 100, centerY - 150, wheelchairColor, accentColor);

  // Pulse rings
  for (int i = 1; i <= 3; i++) {
    _drawCircleOutline(image, centerX, centerY, 100 + i * 30, 2, img.ColorRgb8(accentColor.r.toInt(), accentColor.g.toInt(), accentColor.b.toInt()));
  }

  // Text "ONE WAY" at bottom
  // Note: We can't easily draw text without a font, so we'll skip it for the icon
  // The icon itself is recognizable enough

  // Save as PNG
  final pngBytes = img.encodePng(image);
  final file = File('assets/images/app_icon_1024.png');
  file.writeAsBytesSync(pngBytes);
  print('Generated 1024x1024 icon');

  // Generate all required sizes for Android
  final androidSizes = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
  };

  for (final entry in androidSizes.entries) {
    final resized = img.copyResize(image, width: entry.value, height: entry.value);
    final dir = Directory('android/app/src/main/res/${entry.key}');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    final file = File('${dir.path}/ic_launcher.png');
    file.writeAsBytesSync(img.encodePng(resized));
    print('Generated Android ${entry.key}: ${entry.value}x${entry.value}');
  }

  // Generate iOS sizes
  final iosSizes = {
    'Icon-App-20x20@1x.png': 20,
    'Icon-App-20x20@2x.png': 40,
    'Icon-App-20x20@3x.png': 60,
    'Icon-App-29x29@1x.png': 29,
    'Icon-App-29x29@2x.png': 58,
    'Icon-App-29x29@3x.png': 87,
    'Icon-App-40x40@1x.png': 40,
    'Icon-App-40x40@2x.png': 80,
    'Icon-App-40x40@3x.png': 120,
    'Icon-App-60x60@2x.png': 120,
    'Icon-App-60x60@3x.png': 180,
    'Icon-App-76x76@1x.png': 76,
    'Icon-App-76x76@2x.png': 152,
    'Icon-App-83.5x83.5@2x.png': 167,
    'Icon-App-1024x1024@1x.png': 1024,
  };

  final iosDir = Directory('ios/Runner/Assets.xcassets/AppIcon.appiconset');
  if (!iosDir.existsSync()) {
    iosDir.createSync(recursive: true);
  }

  for (final entry in iosSizes.entries) {
    final resized = img.copyResize(image, width: entry.value, height: entry.value);
    final file = File('${iosDir.path}/${entry.key}');
    file.writeAsBytesSync(img.encodePng(resized));
    print('Generated iOS ${entry.key}: ${entry.value}x${entry.value}');
  }

  // Generate web icons
  final webDir = Directory('web/icons');
  if (!webDir.existsSync()) {
    webDir.createSync(recursive: true);
  }
  final webSizes = [16, 32, 48, 72, 96, 128, 144, 152, 192, 384, 512];
  for (final s in webSizes) {
    final resized = img.copyResize(image, width: s, height: s);
    final file = File('${webDir.path}/icon-${s}x${s}.png');
    file.writeAsBytesSync(img.encodePng(resized));
    print('Generated web icon-${s}x${s}.png');
  }

  // Generate manifest.json for PWA
  final manifest = {
    'name': 'ONEWAY - مصر بدون عوائق',
    'short_name': 'ONEWAY',
    'description': 'تطبيق لاكتشاف الأماكن المجهزة لذوي الإعاقة في مصر',
    'start_url': '/',
    'display': 'standalone',
    'background_color': '#0F172A',
    'theme_color': '#F59E0B',
    'orientation': 'portrait-primary',
    'icons': webSizes.map((s) => {
      'src': 'icons/icon-${s}x${s}.png',
      'sizes': '${s}x${s}',
      'type': 'image/png',
      'purpose': 'any maskable',
    }).toList(),
  };
  File('web/manifest.json').writeAsStringSync(JsonEncoder.withIndent('  ').convert(manifest));
  print('Generated web/manifest.json');

  print('All icons generated successfully!');
}

void _drawCircle(img.Image image, int cx, int cy, int radius, img.Color color) {
  for (int y = -radius; y <= radius; y++) {
    for (int x = -radius; x <= radius; x++) {
      if (x * x + y * y <= radius * radius) {
        final px = cx + x;
        final py = cy + y;
        if (px >= 0 && px < image.width && py >= 0 && py < image.height) {
          image.setPixel(px, py, color);
        }
      }
    }
  }
}

void _drawCircleOutline(img.Image image, int cx, int cy, int radius, int thickness, img.Color color) {
  for (int y = -radius; y <= radius; y++) {
    for (int x = -radius; x <= radius; x++) {
      final dist = math.sqrt((x * x + y * y).toDouble());
      if (dist >= radius - thickness && dist <= radius) {
        final px = cx + x;
        final py = cy + y;
        if (px >= 0 && px < image.width && py >= 0 && py < image.height) {
          image.setPixel(px, py, color);
        }
      }
    }
  }
}

void _drawRect(img.Image image, int x, int y, int width, int height, img.Color color) {
  for (int i = 0; i < width; i++) {
    for (int j = 0; j < height; j++) {
      final px = x + i;
      final py = y + j;
      if (px >= 0 && px < image.width && py >= 0 && py < image.height) {
        image.setPixel(px, py, color);
      }
    }
  }
}

void _drawLine(img.Image image, int x1, int y1, int x2, int y2, int thickness, img.Color color) {
  final dx = x2 - x1;
  final dy = y2 - y1;
  final steps = (dx.abs() > dy.abs() ? dx.abs() : dy.abs()).toInt();
  if (steps == 0) return;
  for (int i = 0; i <= steps; i++) {
    final t = i / steps;
    final x = (x1 + dx * t).round();
    final y = (y1 + dy * t).round();
    _drawCircle(image, x, y, thickness ~/ 2, color);
  }
}

void _drawLocationPin(img.Image image, int cx, int cy, img.Color mainColor, img.Color accentColor) {
  // Pin body
  for (int y = 0; y < 50; y++) {
    final width = (25 * (1 - y / 50)).round();
    for (int x = -width; x <= width; x++) {
      final px = cx + x;
      final py = cy - y;
      if (px >= 0 && px < image.width && py >= 0 && py < image.height) {
        image.setPixel(px, py, mainColor);
      }
    }
  }
  // Pin head circle
  _drawCircle(image, cx, cy - 50, 25, mainColor);
  _drawCircle(image, cx, cy - 50, 12, accentColor);
}