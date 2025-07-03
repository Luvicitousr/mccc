import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_localizations.dart';

/// 🌍 Gerenciador de Idiomas
///
/// Responsável por:
/// - Gerenciar o idioma selecionado pelo usuário
/// - Persistir a escolha de idioma
/// - Fornecer métodos para mudança de idioma
/// - Detectar idioma do sistema
class LanguageManager extends ChangeNotifier {
  static LanguageManager? _instance;
  static LanguageManager get instance => _instance ??= LanguageManager._();

  LanguageManager._();

  static const String _languageKey = 'selected_language';
  Locale _currentLocale = const Locale('pt', 'BR'); // Padrão: Português

  /// 🎯 Getters
  Locale get currentLocale => _currentLocale;
  String get currentLanguageCode => _currentLocale.languageCode;
  String get currentLanguageName =>
      AppLocalizations.getLanguageName(currentLanguageCode);
  bool get isRTL => AppLocalizations.isRTL(currentLanguageCode);

  /// 🚀 Inicializa o gerenciador
  Future<void> initialize() async {
    await _loadSavedLanguage();
  }

  /// 💾 Carrega idioma salvo ou detecta do sistema
  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguageCode = prefs.getString(_languageKey);

      if (savedLanguageCode != null) {
        // Usa idioma salvo
        _setLocaleFromCode(savedLanguageCode);
      } else {
        // Detecta idioma do sistema
        _detectSystemLanguage();
      }
    } catch (e) {
      print('[LANGUAGE_MANAGER] Erro ao carregar idioma: $e');
      // Usa padrão em caso de erro
      _currentLocale = const Locale('pt', 'BR');
    }
  }

  /// 🔍 Detecta idioma do sistema
  void _detectSystemLanguage() {
    final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;
    final systemLanguageCode = systemLocale.languageCode;

    // Verifica se o idioma do sistema é suportado
    final isSupported = AppLocalizations.supportedLocales
        .any((locale) => locale.languageCode == systemLanguageCode);

    if (isSupported) {
      _setLocaleFromCode(systemLanguageCode);
    } else {
      // Usa inglês como fallback
      _currentLocale = const Locale('en', 'US');
    }
  }

  /// 🔧 Define locale a partir do código do idioma
  void _setLocaleFromCode(String languageCode) {
    final supportedLocale = AppLocalizations.supportedLocales.firstWhere(
      (locale) => locale.languageCode == languageCode,
      orElse: () => const Locale('en', 'US'),
    );

    _currentLocale = supportedLocale;
  }

  /// 🌍 Muda o idioma
  Future<void> changeLanguage(String languageCode) async {
    if (languageCode == currentLanguageCode) return;

    try {
      _setLocaleFromCode(languageCode);

      // Salva a escolha
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);

      // Notifica mudança
      notifyListeners();

      print('[LANGUAGE_MANAGER] Idioma alterado para: $currentLanguageName');
    } catch (e) {
      print('[LANGUAGE_MANAGER] Erro ao alterar idioma: $e');
    }
  }

  /// 📋 Obtém lista de idiomas disponíveis
  List<LanguageOption> getAvailableLanguages() {
    return AppLocalizations.supportedLocales.map((locale) {
      return LanguageOption(
        code: locale.languageCode,
        name: AppLocalizations.getLanguageName(locale.languageCode),
        locale: locale,
        isRTL: AppLocalizations.isRTL(locale.languageCode),
      );
    }).toList();
  }

  /// 🔄 Reset para idioma padrão
  Future<void> resetToDefault() async {
    await changeLanguage('pt');
  }
}

/// 📋 Opção de idioma
class LanguageOption {
  final String code;
  final String name;
  final Locale locale;
  final bool isRTL;

  LanguageOption({
    required this.code,
    required this.name,
    required this.locale,
    required this.isRTL,
  });

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LanguageOption && other.code == code;
  }

  @override
  int get hashCode => code.hashCode;
}
