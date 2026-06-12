import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/user.dart';
import '../theme/app_theme.dart';

class AvatarWidget extends StatelessWidget {
  final User user;
  final double size;
  final bool showBorder;

  const AvatarWidget({
    super.key,
    required this.user,
    this.size = 50,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.zinc900,
        border: showBorder
            ? Border.all(color: AppTheme.white.withValues(alpha: 0.1), width: size * 0.05)
            : null,
      ),
      child: ClipOval(
        child: _buildAvatarContent(context),
      ),
    );
  }

  Widget _buildAvatarContent(BuildContext context) {
    if (user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: user.profileImageUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(color: AppTheme.zinc900),
        errorWidget: (context, url, error) => _buildDefaultSvg(),
      );
    }
    return _buildDefaultSvg();
  }

  Widget _buildDefaultSvg() {
    final assetPath = user.gender == 'female'
        ? 'assets/avatars/female_default.svg'
        : 'assets/avatars/male_default.svg';

    return SvgPicture.asset(
      assetPath,
      fit: BoxFit.cover,
      width: size,
      height: size,
    );
  }
}
