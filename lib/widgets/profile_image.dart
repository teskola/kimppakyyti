import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ProfileImage extends StatelessWidget {
  final String? url;
  final double? radius;
  const ProfileImage(this.url, {super.key, this.radius});

  @override
  Widget build(BuildContext context) {
    return url == null
        ? const CircleAvatar(backgroundColor: Colors.grey)
        : CachedNetworkImage(
            imageUrl: url!,
            imageBuilder: (_, imageProvider) =>
                CircleAvatar(radius: radius, backgroundImage: imageProvider),
            placeholder: (_, __) => const CircularProgressIndicator(),
            errorWidget: (_, __, ___) => const CircleAvatar(
              backgroundColor: Colors.grey,
            ),
          );
  }
}
