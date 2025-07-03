import 'package:flutter/material.dart';

/// 🌍 Sistema de Localização do Aplicativo
///
/// Implementa um sistema completo de internacionalização com:
/// - Suporte a múltiplos idiomas
/// - Carregamento dinâmico de textos
/// - Formatação adequada para cada idioma
/// - Suporte a RTL (Right-to-Left) quando necessário
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// 🎯 Textos da aplicação baseados no idioma selecionado

  // Textos gerais
  String get appTitle => _getText('app_title');
  String get settings => _getText('settings');
  String get back => _getText('back');
  String get save => _getText('save');
  String get cancel => _getText('cancel');
  String get ok => _getText('ok');
  String get yes => _getText('yes');
  String get no => _getText('no');
  String get loading => _getText('loading');
  String get error => _getText('error');
  String get success => _getText('success');

  // Menu principal
  String get play => _getText('play');
  String get levelSelection => _getText('level_selection');
  String get mainMenu => _getText('main_menu');
  String get gameTitle => _getText('game_title');
  String get gameSubtitle => _getText('game_subtitle');

  // Seleção de níveis
  String get levelSelectionTitle => _getText('level_selection_title');
  String get levelSelectionSubtitle => _getText('level_selection_subtitle');
  String get level => _getText('level');
  String get locked => _getText('locked');
  String get completed => _getText('completed');
  String get stars => _getText('stars');

  // Configurações - Seções
  String get audioSettings => _getText('audio_settings');
  String get audioSettingsSubtitle => _getText('audio_settings_subtitle');
  String get experienceSettings => _getText('experience_settings');
  String get experienceSettingsSubtitle =>
      _getText('experience_settings_subtitle');
  String get personalizationSettings => _getText('personalization_settings');
  String get personalizationSettingsSubtitle =>
      _getText('personalization_settings_subtitle');

  // Configurações - Áudio
  String get gameSounds => _getText('game_sounds');
  String get backgroundMusic => _getText('background_music');
  String get musicVolume => _getText('music_volume');
  String get effectsVolume => _getText('effects_volume');

  // Configurações - Experiência
  String get hapticFeedback => _getText('haptic_feedback');
  String get notifications => _getText('notifications');

  // Configurações - Personalização
  String get language => _getText('language');
  String get visualTheme => _getText('visual_theme');
  String get restoreDefaults => _getText('restore_defaults');

  // Temas
  String get themeClassicZen => _getText('theme_classic_zen');
  String get themeCherryBlossom => _getText('theme_cherry_blossom');
  String get themeBamboo => _getText('theme_bamboo');

  // Mensagens
  String get settingsRestored => _getText('settings_restored');
  String get settingsSaved => _getText('settings_saved');
  String get gameOver => _getText('game_over');
  String get victory => _getText('victory');
  String get moves => _getText('moves');
  String get objectives => _getText('objectives');

  // Jogo
  String get pause => _getText('pause');
  String get resume => _getText('resume');
  String get restart => _getText('restart');
  String get nextLevel => _getText('next_level');
  String get continueJourney => _getText('continue_journey');
  String get menu => _getText('menu');

  /// 🔍 Método interno para obter texto baseado na chave
  String _getText(String key) {
    final languageCode = locale.languageCode;

    // Verifica se o idioma está disponível, senão usa inglês como fallback
    if (_translations.containsKey(languageCode)) {
      return _translations[languageCode]![key] ??
          _translations['en']![key] ??
          key;
    }

    return _translations['en']![key] ?? key;
  }

  /// 📚 Dicionário de traduções
  static const Map<String, Map<String, String>> _translations = {
    'pt': {
      // Textos gerais
      'app_title': 'Garden of Petals',
      'settings': 'Configurações',
      'back': 'Voltar',
      'save': 'Salvar',
      'cancel': 'Cancelar',
      'ok': 'OK',
      'yes': 'Sim',
      'no': 'Não',
      'loading': 'Carregando...',
      'error': 'Erro',
      'success': 'Sucesso',

      // Menu principal
      'play': 'Jogar',
      'level_selection': 'Seleção de Níveis',
      'main_menu': 'Menu Principal',
      'game_title': 'Garden of Petals',
      'game_subtitle': 'Harmonia em cada movimento',

      // Seleção de níveis
      'level_selection_title': 'Caminhos do Jardim',
      'level_selection_subtitle': 'Escolha seu próximo desafio',
      'level': 'Nível',
      'locked': 'Bloqueado',
      'completed': 'Concluído',
      'stars': 'Estrelas',

      // Configurações - Seções
      'audio_settings': 'Configurações de Áudio',
      'audio_settings_subtitle': 'Sons e música do jogo',
      'experience_settings': 'Configurações de Experiência',
      'experience_settings_subtitle': 'Feedback e notificações',
      'personalization_settings': 'Configurações Pessoais',
      'personalization_settings_subtitle': 'Idioma e aparência',

      // Configurações - Áudio
      'game_sounds': 'Sons do Jogo',
      'background_music': 'Música de Fundo',
      'music_volume': 'Volume da Música',
      'effects_volume': 'Volume dos Efeitos',

      // Configurações - Experiência
      'haptic_feedback': 'Feedback Tátil',
      'notifications': 'Notificações',

      // Configurações - Personalização
      'language': 'Idioma',
      'visual_theme': 'Tema Visual',
      'restore_defaults': 'Restaurar Padrões',

      // Temas
      'theme_classic_zen': 'Zen Clássico',
      'theme_cherry_blossom': 'Cerejeira',
      'theme_bamboo': 'Bambu',

      // Mensagens
      'settings_restored': 'Configurações restauradas aos padrões',
      'settings_saved': 'Configurações salvas com sucesso',
      'game_over': 'Fim de Jogo',
      'victory': 'Vitória',
      'moves': 'Movimentos',
      'objectives': 'Objetivos',

      // Jogo
      'pause': 'Pausar',
      'resume': 'Continuar',
      'restart': 'Reiniciar',
      'next_level': 'Próximo Nível',
      'continue_journey': 'Continuar Jornada',
      'menu': 'Menu',
    },
    'en': {
      // General texts
      'app_title': 'Garden of Petals',
      'settings': 'Settings',
      'back': 'Back',
      'save': 'Save',
      'cancel': 'Cancel',
      'ok': 'OK',
      'yes': 'Yes',
      'no': 'No',
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',

      // Main menu
      'play': 'Play',
      'level_selection': 'Level Selection',
      'main_menu': 'Main Menu',
      'game_title': 'Garden of Petals',
      'game_subtitle': 'Harmony in every move',

      // Level selection
      'level_selection_title': 'Garden Paths',
      'level_selection_subtitle': 'Choose your next challenge',
      'level': 'Level',
      'locked': 'Locked',
      'completed': 'Completed',
      'stars': 'Stars',

      // Settings - Sections
      'audio_settings': 'Audio Settings',
      'audio_settings_subtitle': 'Game sounds and music',
      'experience_settings': 'Experience Settings',
      'experience_settings_subtitle': 'Feedback and notifications',
      'personalization_settings': 'Personal Settings',
      'personalization_settings_subtitle': 'Language and appearance',

      // Settings - Audio
      'game_sounds': 'Game Sounds',
      'background_music': 'Background Music',
      'music_volume': 'Music Volume',
      'effects_volume': 'Effects Volume',

      // Settings - Experience
      'haptic_feedback': 'Haptic Feedback',
      'notifications': 'Notifications',

      // Settings - Personalization
      'language': 'Language',
      'visual_theme': 'Visual Theme',
      'restore_defaults': 'Restore Defaults',

      // Themes
      'theme_classic_zen': 'Classic Zen',
      'theme_cherry_blossom': 'Cherry Blossom',
      'theme_bamboo': 'Bamboo',

      // Messages
      'settings_restored': 'Settings restored to defaults',
      'settings_saved': 'Settings saved successfully',
      'game_over': 'Game Over',
      'victory': 'Victory',
      'moves': 'Moves',
      'objectives': 'Objectives',

      // Game
      'pause': 'Pause',
      'resume': 'Resume',
      'restart': 'Restart',
      'next_level': 'Next Level',
      'continue_journey': 'Continue Journey',
      'menu': 'Menu',
    },
    'ja': {
      // 一般的なテキスト
      'app_title': '花びらの庭',
      'settings': '設定',
      'back': '戻る',
      'save': '保存',
      'cancel': 'キャンセル',
      'ok': 'OK',
      'yes': 'はい',
      'no': 'いいえ',
      'loading': '読み込み中...',
      'error': 'エラー',
      'success': '成功',

      // メインメニュー
      'play': 'プレイ',
      'level_selection': 'レベル選択',
      'main_menu': 'メインメニュー',
      'game_title': '花びらの庭',
      'game_subtitle': '一つ一つの動きに調和を',

      // レベル選択
      'level_selection_title': '庭園の道',
      'level_selection_subtitle': '次の挑戦を選択',
      'level': 'レベル',
      'locked': 'ロック済み',
      'completed': '完了',
      'stars': '星',

      // 設定 - セクション
      'audio_settings': '音響設定',
      'audio_settings_subtitle': 'ゲームの音と音楽',
      'experience_settings': '体験設定',
      'experience_settings_subtitle': 'フィードバックと通知',
      'personalization_settings': '個人設定',
      'personalization_settings_subtitle': '言語と外観',

      // 設定 - オーディオ
      'game_sounds': 'ゲーム音',
      'background_music': 'バックグラウンド音楽',
      'music_volume': '音楽の音量',
      'effects_volume': '効果音の音量',

      // 設定 - 体験
      'haptic_feedback': '触覚フィードバック',
      'notifications': '通知',

      // 設定 - 個人化
      'language': '言語',
      'visual_theme': 'ビジュアルテーマ',
      'restore_defaults': 'デフォルトに戻す',

      // テーマ
      'theme_classic_zen': 'クラシック禅',
      'theme_cherry_blossom': '桜',
      'theme_bamboo': '竹',

      // メッセージ
      'settings_restored': '設定がデフォルトに復元されました',
      'settings_saved': '設定が正常に保存されました',
      'game_over': 'ゲームオーバー',
      'victory': '勝利',
      'moves': '動き',
      'objectives': '目標',

      // ゲーム
      'pause': '一時停止',
      'resume': '再開',
      'restart': '再開始',
      'next_level': '次のレベル',
      'continue_journey': '旅を続ける',
      'menu': 'メニュー',
    },
    'es': {
      // Textos generales
      'app_title': 'Jardín de Pétalos',
      'settings': 'Configuración',
      'back': 'Atrás',
      'save': 'Guardar',
      'cancel': 'Cancelar',
      'ok': 'OK',
      'yes': 'Sí',
      'no': 'No',
      'loading': 'Cargando...',
      'error': 'Error',
      'success': 'Éxito',

      // Menú principal
      'play': 'Jugar',
      'level_selection': 'Selección de Nivel',
      'main_menu': 'Menú Principal',
      'game_title': 'Jardín de Pétalos',
      'game_subtitle': 'Armonía en cada movimiento',

      // Selección de niveles
      'level_selection_title': 'Senderos del Jardín',
      'level_selection_subtitle': 'Elige tu próximo desafío',
      'level': 'Nivel',
      'locked': 'Bloqueado',
      'completed': 'Completado',
      'stars': 'Estrellas',

      // Configuración - Secciones
      'audio_settings': 'Configuración de Audio',
      'audio_settings_subtitle': 'Sonidos y música del juego',
      'experience_settings': 'Configuración de Experiencia',
      'experience_settings_subtitle': 'Retroalimentación y notificaciones',
      'personalization_settings': 'Configuración Personal',
      'personalization_settings_subtitle': 'Idioma y apariencia',

      // Configuración - Audio
      'game_sounds': 'Sonidos del Juego',
      'background_music': 'Música de Fondo',
      'music_volume': 'Volumen de Música',
      'effects_volume': 'Volumen de Efectos',

      // Configuración - Experiencia
      'haptic_feedback': 'Retroalimentación Háptica',
      'notifications': 'Notificaciones',

      // Configuración - Personalización
      'language': 'Idioma',
      'visual_theme': 'Tema Visual',
      'restore_defaults': 'Restaurar Predeterminados',

      // Temas
      'theme_classic_zen': 'Zen Clásico',
      'theme_cherry_blossom': 'Flor de Cerezo',
      'theme_bamboo': 'Bambú',

      // Mensajes
      'settings_restored': 'Configuración restaurada a predeterminados',
      'settings_saved': 'Configuración guardada exitosamente',
      'game_over': 'Fin del Juego',
      'victory': 'Victoria',
      'moves': 'Movimientos',
      'objectives': 'Objetivos',

      // Juego
      'pause': 'Pausar',
      'resume': 'Reanudar',
      'restart': 'Reiniciar',
      'next_level': 'Siguiente Nivel',
      'continue_journey': 'Continuar Viaje',
      'menu': 'Menú',
    },
    'fr': {
      // Textes généraux
      'app_title': 'Jardin de Pétales',
      'settings': 'Paramètres',
      'back': 'Retour',
      'save': 'Sauvegarder',
      'cancel': 'Annuler',
      'ok': 'OK',
      'yes': 'Oui',
      'no': 'Non',
      'loading': 'Chargement...',
      'error': 'Erreur',
      'success': 'Succès',

      // Menu principal
      'play': 'Jouer',
      'level_selection': 'Sélection de Niveau',
      'main_menu': 'Menu Principal',
      'game_title': 'Jardin de Pétales',
      'game_subtitle': 'Harmonie dans chaque mouvement',

      // Sélection de niveaux
      'level_selection_title': 'Chemins du Jardin',
      'level_selection_subtitle': 'Choisissez votre prochain défi',
      'level': 'Niveau',
      'locked': 'Verrouillé',
      'completed': 'Terminé',
      'stars': 'Étoiles',

      // Paramètres - Sections
      'audio_settings': 'Paramètres Audio',
      'audio_settings_subtitle': 'Sons et musique du jeu',
      'experience_settings': 'Paramètres d\'Expérience',
      'experience_settings_subtitle': 'Retour et notifications',
      'personalization_settings': 'Paramètres Personnels',
      'personalization_settings_subtitle': 'Langue et apparence',

      // Paramètres - Audio
      'game_sounds': 'Sons du Jeu',
      'background_music': 'Musique de Fond',
      'music_volume': 'Volume de la Musique',
      'effects_volume': 'Volume des Effets',

      // Paramètres - Expérience
      'haptic_feedback': 'Retour Haptique',
      'notifications': 'Notifications',

      // Paramètres - Personnalisation
      'language': 'Langue',
      'visual_theme': 'Thème Visuel',
      'restore_defaults': 'Restaurer les Défauts',

      // Thèmes
      'theme_classic_zen': 'Zen Classique',
      'theme_cherry_blossom': 'Fleur de Cerisier',
      'theme_bamboo': 'Bambou',

      // Messages
      'settings_restored': 'Paramètres restaurés aux défauts',
      'settings_saved': 'Paramètres sauvegardés avec succès',
      'game_over': 'Fin de Jeu',
      'victory': 'Victoire',
      'moves': 'Mouvements',
      'objectives': 'Objectifs',

      // Jeu
      'pause': 'Pause',
      'resume': 'Reprendre',
      'restart': 'Redémarrer',
      'next_level': 'Niveau Suivant',
      'continue_journey': 'Continuer le Voyage',
      'menu': 'Menu',
    },
  };

  /// 🌍 Lista de idiomas suportados
  static const List<Locale> supportedLocales = [
    Locale('pt', 'BR'), // Português (Brasil)
    Locale('en', 'US'), // English (US)
    Locale('ja', 'JP'), // 日本語 (Japan)
    Locale('es', 'ES'), // Español (España)
    Locale('fr', 'FR'), // Français (France)
  ];

  /// 🔍 Obtém nome do idioma para exibição
  static String getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'pt':
        return 'Português';
      case 'en':
        return 'English';
      case 'ja':
        return '日本語';
      case 'es':
        return 'Español';
      case 'fr':
        return 'Français';
      default:
        return 'English';
    }
  }

  /// 📱 Verifica se o idioma é RTL (Right-to-Left)
  static bool isRTL(String languageCode) {
    // Adicione códigos de idioma RTL aqui se necessário
    const rtlLanguages = ['ar', 'he', 'fa', 'ur'];
    return rtlLanguages.contains(languageCode);
  }
}

/// 🔧 Delegate para carregamento de localizações
class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any((supportedLocale) =>
        supportedLocale.languageCode == locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
