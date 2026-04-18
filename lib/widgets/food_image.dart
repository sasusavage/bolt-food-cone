import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Network food image with rounded corners + tasteful fallback.
class FoodImage extends StatelessWidget {
  final String? url;
  final double width;
  final double height;
  final double radius;
  final BoxFit fit;

  const FoodImage({
    super.key,
    required this.url,
    this.width = double.infinity,
    this.height = 160,
    this.radius = AppRadius.md,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: (url == null || url!.isEmpty)
          ? _Placeholder(width: width, height: height)
          : CachedNetworkImage(
              imageUrl: url!,
              width: width,
              height: height,
              fit: fit,
              placeholder: (_, __) =>
                  _Placeholder(width: width, height: height, loading: true),
              errorWidget: (_, __, ___) =>
                  _Placeholder(width: width, height: height),
            ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final double width;
  final double height;
  final bool loading;

  const _Placeholder({
    required this.width,
    required this.height,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF5E6DE), Color(0xFFFFF0EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.primary),
              )
            : const Icon(Icons.restaurant,
                color: AppColors.primary, size: 28),
      ),
    );
  }
}
