import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// IDs de teste públicos do Google. Trocar pelos IDs reais do AdMob (e pelo
/// App ID real no AndroidManifest.xml) antes de publicar na Play Store.
///
/// google_mobile_ads não roda na web — este projeto só publica pra Android,
/// mas o Flutter Web ainda é usado localmente pra testar rapidamente outras
/// telas neste ambiente de dev, então tudo aqui vira no-op quando `kIsWeb`.
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  static const String bannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String interstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';

  static const int _actionsPerInterstitial = 5;

  InterstitialAd? _interstitialAd;
  int _actionCount = 0;

  Future<void> initialize() async {
    if (kIsWeb) return;
    await MobileAds.instance.initialize();
    loadInterstitial();
  }

  BannerAd? createBannerAd({
    required void Function(Ad ad) onLoaded,
    required void Function(Ad ad, LoadAdError error) onFailed,
  }) {
    if (kIsWeb) return null;

    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: onLoaded,
        onAdFailedToLoad: onFailed,
      ),
    )..load();
  }

  void loadInterstitial() {
    if (kIsWeb) return;

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (_) => _interstitialAd = null,
      ),
    );
  }

  /// Chamar após ações do usuário (download, compartilhar). Mostra um
  /// intersticial a cada [_actionsPerInterstitial] chamadas.
  void registerActionAndMaybeShow() {
    if (kIsWeb) return;

    _actionCount++;
    if (_actionCount < _actionsPerInterstitial) return;
    _actionCount = 0;

    final ad = _interstitialAd;
    if (ad == null) {
      loadInterstitial();
      return;
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        loadInterstitial();
      },
    );
    ad.show();
  }
}
