import 'package:flutter/material.dart';

class SponsoredAdItem {
  final String id;
  final String advertiser;
  final String title;
  final String imageUrl;
  final String cta;
  final double aspectRatio; // width / height
  final Color? accent;

  const SponsoredAdItem({
    required this.id,
    required this.advertiser,
    required this.title,
    required this.imageUrl,
    required this.cta,
    required this.aspectRatio,
    this.accent,
  });
}

/// Simple mock ads provider for previews and desktop rails
class AdsService {
  // Static list of leaderboard/header ads for desktop (horizontal format)
  static const _leaderboardAds = <SponsoredAdItem>[
    SponsoredAdItem(
      id: 'lead_1',
      advertiser: 'CloudSync Pro',
      title: 'Sync your workflow across all devices',
      imageUrl: 'https://picsum.photos/800/120?random=60',
      cta: 'Try Free',
      aspectRatio: 6.67, // 800x120 leaderboard format
      accent: Color(0xFF2196F3),
    ),
    SponsoredAdItem(
      id: 'lead_2',
      advertiser: 'DevTools Suite',
      title: 'Debug like a pro with advanced analytics',
      imageUrl: 'https://picsum.photos/800/120?random=61',
      cta: 'Get Started',
      aspectRatio: 6.67,
      accent: Color(0xFF9C27B0),
    ),
    SponsoredAdItem(
      id: 'lead_3',
      advertiser: 'SecureVault',
      title: 'Password management made simple',
      imageUrl: 'https://picsum.photos/800/120?random=62',
      cta: 'Learn More',
      aspectRatio: 6.67,
      accent: Color(0xFF4CAF50),
    ),
  ];

  // Static list of realistic-looking banner assets (mock)
  static const _leftRailAds = <SponsoredAdItem>[
    SponsoredAdItem(
      id: 'ad_mock_1',
      advertiser: 'NovaTech',
      title: 'Ship apps 10x faster',
      imageUrl: 'https://pixabay.com/get/g514d0346fde96e74fe4c8b435b9b25fcd396e29546fb60d1d449a7396e7744a1d4cc7c1f252fdb03c329b16dcff2132e72100a5dd06cf6de86e580b27259d9b6_1280.jpg',
      cta: 'Start free',
      aspectRatio: 300 / 600,
    ),
    SponsoredAdItem(
      id: 'ad_mock_2',
      advertiser: 'CleanGrid',
      title: 'Powering a greener web',
      imageUrl: 'https://pixabay.com/get/gd979907546406d5a6dde9c07cef64fb1d63fcb1f47a1f829d324c99e78a35d05bd9f977f20a7c6541441ec0f54a93a3954f155275d042ed91dd6642f95d358d3_1280.jpg',
      cta: 'Learn more',
      aspectRatio: 300 / 250,
    ),
    SponsoredAdItem(
      id: 'ad_mock_7',
      advertiser: 'SkyBridge',
      title: 'Scale your startup',
      imageUrl: 'https://pixabay.com/get/gc623d78850f22281343dad64c368ac83981fbeb414e7d3565667666c55c54f6e1d5f32a3e98809f14ab9b45854f84f0990279256a77306b35af7890d9831b35e_1280.jpg',
      cta: 'Apply now',
      aspectRatio: 300 / 250,
    ),
    SponsoredAdItem(
      id: 'ad_mock_8',
      advertiser: 'WindWorks',
      title: 'Offset your carbon',
      imageUrl: 'https://pixabay.com/get/g940c79f62fd24fd0924dad19b4ddd4c3a949efb28978dfd07383ae3b21cf2ed1d5b9879d25063b1ba7e74a61b9d0a4c7c8fa5b92b598b628d5985746a6e46131_1280.jpg',
      cta: 'Go green',
      aspectRatio: 300 / 600,
    ),
  ];

  static const _rightRailAds = <SponsoredAdItem>[
    SponsoredAdItem(
      id: 'ad_mock_3',
      advertiser: 'LockWorks',
      title: 'Protect your data',
      imageUrl: 'https://pixabay.com/get/g987cff14b854df3c41c8a6d199b6da9ceae6120a11597d0140322956a96b4827ae7f1b476e864e2e97678668d9e67fce6ede6330915b350be83ec300b6f97dc4_1280.jpg',
      cta: 'Enable shield',
      aspectRatio: 300 / 600,
    ),
    SponsoredAdItem(
      id: 'ad_mock_4',
      advertiser: 'FinPilot',
      title: 'Make smarter moves',
      imageUrl: 'https://pixabay.com/get/g7531a2c65f33732af8783f0fbbdef756d97ebdbf5b8e22284f55eb3987b9b8c3c07dc0192809575eee333032d56aca1f8c2fd56e898022e5184fef1fc649b9dc_1280.jpg',
      cta: 'Try it',
      aspectRatio: 300 / 250,
    ),
    SponsoredAdItem(
      id: 'ad_mock_9',
      advertiser: 'FlowDesk',
      title: 'Designed for deep focus',
      imageUrl: 'https://pixabay.com/get/g123c42c91b9508d632edec167fcc7810975fc43e81ae4301e3b8a6d567a2865ebcb5243e016220d84ad764666171bba3e5b1402e947fc47c2305023c240d0497_1280.jpg',
      cta: 'See setups',
      aspectRatio: 300 / 250,
    ),
    SponsoredAdItem(
      id: 'ad_mock_10',
      advertiser: 'AegisAI',
      title: 'AI that defends',
      imageUrl: 'https://pixabay.com/get/gb397926b9a0d7286b0228cadb0c77ed6f41235d2f397893711d5db7698f9e4a70ed87b24a0c8f7ff99517ec6bc27fa5043cbce22dd80fa3f8b29e7c799d7586d_1280.jpg',
      cta: 'Discover',
      aspectRatio: 300 / 600,
    ),
  ];

  static const _inlineSideAd = SponsoredAdItem(
    id: 'ad_mock_5',
    advertiser: 'Taskly',
    title: 'Focus meets flow',
    imageUrl: 'https://pixabay.com/get/g7b0682b903a6f4b85609693096342ae9115e72128782b8f170f71f9182911fbfb64fd7ba184bb47cddc737bb207857fdc9b5e7098ea24366579ffe47e2b02601_1280.jpg',
    cta: 'Get started',
    aspectRatio: 300 / 250,
  );

  static const _leaderboard = SponsoredAdItem(
    id: 'ad_mock_6',
    advertiser: 'Appify',
    title: 'Your app, everywhere',
    imageUrl: 'https://pixabay.com/get/gddb36ccd08d69d15d576c3d423c4d638367e28a24f9f0f56d31b1e7169faa9a21091cd2061959060955988e994ed9ceb59113c931ce9003d6623b52d014fd041_1280.jpg',
    cta: 'Explore',
    aspectRatio: 728 / 90,
  );

  /// Get a leaderboard/header ad for desktop (horizontal format)
  static SponsoredAdItem getLeaderboardAd() {
    return _leaderboardAds[DateTime.now().millisecondsSinceEpoch % _leaderboardAds.length];
  }

  static List<SponsoredAdItem> leftRailAds() => List.of(_leftRailAds);
  static List<SponsoredAdItem> rightRailAds() => List.of(_rightRailAds);
  static SponsoredAdItem sideRailBoxAd() => _inlineSideAd;
  static SponsoredAdItem headerLeaderboard() => _leaderboard;
}
