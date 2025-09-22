import 'package:flutter/material.dart';
import 'package:trashit/services/ads_service.dart';

class AdBanner extends StatelessWidget {
  final SponsoredAdItem ad;
  final double? width;
  final double? height;
  final bool isLeaderboard;

  const AdBanner({
    super.key,
    required this.ad,
    this.width,
    this.height,
    this.isLeaderboard = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isLeaderboard ? 8 : 12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () {
            debugPrint('Sponsored ad tapped: ${ad.advertiser}');
          },
          child: isLeaderboard ? _buildLeaderboardLayout(context) : _buildVerticalLayout(context),
        ),
      ),
    );
  }

  Widget _buildVerticalLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 3,
          child: Image.network(
            ad.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: Theme.of(context).colorScheme.surfaceContainer,
              child: Icon(
                Icons.image,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sponsored • ${ad.advertiser}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  ad.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton(
                    onPressed: () {
                      debugPrint('Sponsored ad CTA: ${ad.advertiser}');
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      ad.cta,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardLayout(BuildContext context) {
    return Row(
      children: [
        // Compact image on left
        SizedBox(
          width: 100,
          height: height ?? 80,
          child: Image.network(
            ad.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: Theme.of(context).colorScheme.surfaceContainer,
              child: Icon(
                Icons.image,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
        // Text content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Sponsored • ${ad.advertiser}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  ad.title,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
        // CTA button
        Padding(
          padding: const EdgeInsets.all(8),
          child: OutlinedButton(
            onPressed: () {
              debugPrint('Sponsored ad CTA: ${ad.advertiser}');
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              ad.cta,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ),
      ],
    );
  }
}

class AdBannerBox extends StatelessWidget {
  final SponsoredAdItem ad;
  final double maxWidth;
  final EdgeInsetsGeometry margin;
  final bool showFrame;

  const AdBannerBox({
    super.key,
    required this.ad,
    required this.maxWidth,
    this.margin = const EdgeInsets.symmetric(vertical: 8),
    this.showFrame = true,
  });

  @override
  Widget build(BuildContext context) {
    final width = maxWidth;
    final height = width / (ad.aspectRatio == 0 ? 1 : ad.aspectRatio);

    return Container(
      margin: margin,
      child: AdBanner(
        ad: ad,
        width: width,
        height: height,
      ),
    );
  }
}

class AdRail extends StatelessWidget {
  final List<SponsoredAdItem> ads;
  final double width;
  
  const AdRail({
    super.key,
    required this.ads,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      itemCount: ads.length,
      itemBuilder: (context, index) {
        return AdBannerBox(ad: ads[index], maxWidth: width - 16);
      },
    );
  }
}