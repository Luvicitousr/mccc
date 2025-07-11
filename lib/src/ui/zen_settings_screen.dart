import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import '../game/game_state_manager.dart';
import 'smooth_page_transitions.dart';
import 'i18n/app_localizations.dart';
import 'i18n/language_manager.dart';

/// 🧘 Tela de Configurações Zen Japonesa - VERSÃO CORRIGIDA PARA OVERFLOW E I18N
/// ✅ CORREÇÕES APLICADAS:
/// - Corrigido RenderFlex overflow de 14 pixels
/// - Implementado sistema completo de i18n
/// - Removido texto japonês hardcoded
/// - Layout completamente responsivo
/// - Suporte a idiomas RTL
/// - Carregamento dinâmico de textos
class ZenSettingsScreen extends StatefulWidget {
  const ZenSettingsScreen({super.key});

  @override
  State<ZenSettingsScreen> createState() => _ZenSettingsScreenState();
}

class _ZenSettingsScreenState extends State<ZenSettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _rippleController;
  late AnimationController _particleController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  // Estado das configurações locais
  bool _soundEnabled = true;
  bool _musicEnabled = true;
  bool _hapticsEnabled = true;
  bool _notificationsEnabled = true;
  double _musicVolume = 0.7;
  double _sfxVolume = 0.8;
  String _selectedLanguage = 'pt';
  String _selectedTheme = 'zen';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadCurrentSettings();
    _startAnimations();
  }

  void _initializeAnimations() {
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _rippleController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    );

    _particleController = AnimationController(
      duration: const Duration(seconds: 12),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOutQuart),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOutBack),
    ));
  }

  void _loadCurrentSettings() {
    final gameState = context.read<GameStateManager>();
    final languageManager = context.read<LanguageManager>();

    setState(() {
      _soundEnabled = gameState.soundEnabled;
      _musicEnabled = gameState.musicEnabled;
      _hapticsEnabled = gameState.hapticsEnabled;
      _selectedLanguage = languageManager.currentLanguageCode;
    });
  }

  void _startAnimations() {
    _mainController.forward();
    _rippleController.repeat();
    _particleController.repeat();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _rippleController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageManager = context.watch<LanguageManager>();

    // ✅ CORREÇÃO: Suporte a RTL
    return Directionality(
      textDirection:
          languageManager.isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            // ✅ CORREÇÃO PRINCIPAL: Layout responsivo baseado nas dimensões disponíveis
            return Container(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              decoration: const BoxDecoration(
                gradient: ZenGradients.settingsBackground,
              ),
              child: Stack(
                children: [
                  _buildSandTexture(),
                  _buildWaterRipples(),
                  _buildFloatingParticles(constraints),
                  _buildZenStones(constraints),
                  _buildMainContent(l10n, constraints),
                  _buildNavigationBar(l10n, constraints),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// 🏜️ Textura de areia rastejada (karesansui)
  Widget _buildSandTexture() {
    return Positioned.fill(
      child: CustomPaint(
        painter: SandTexturePainter(),
      ),
    );
  }

  /// 🌊 Ondulações de água
  Widget _buildWaterRipples() {
    return AnimatedBuilder(
      animation: _rippleController,
      builder: (context, child) {
        return CustomPaint(
          painter: WaterRipplePainter(_rippleController.value),
          size: Size.infinite,
        );
      },
    );
  }

  /// ✨ Partículas flutuantes responsivas
  Widget _buildFloatingParticles(BoxConstraints constraints) {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return Stack(
          children: List.generate(8, (index) {
            final progress = (_particleController.value + (index * 0.2)) % 1.0;

            return Positioned(
              left: (index * constraints.maxWidth / 8) +
                  (math.sin(progress * math.pi * 2) * 20),
              top: -10 + (progress * (constraints.maxHeight + 20)),
              child: Transform.rotate(
                angle: progress * math.pi * 2 * 0.2,
                child: Opacity(
                  opacity: 0.3 * (1.0 - (progress - 0.8).clamp(0.0, 0.2) * 5),
                  child: _buildZenParticle(index),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildZenParticle(int index) {
    final size = 4.0 + (index % 3) * 2.0;
    final isLeaf = index % 2 == 0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isLeaf
            ? ZenColors.bambooLeaf.withOpacity(0.6)
            : ZenColors.cherryBlossom.withOpacity(0.5),
        borderRadius: BorderRadius.circular(size / 2),
      ),
    );
  }

  /// 🗿 Elementos decorativos responsivos
  Widget _buildZenStones(BoxConstraints constraints) {
    return Stack(
      children: [
        Positioned(
          top: constraints.maxHeight * 0.15,
          right: _getResponsivePadding(constraints.maxWidth),
          child: _buildZenStone(40, 30),
        ),
        Positioned(
          bottom: constraints.maxHeight * 0.2,
          left: _getResponsivePadding(constraints.maxWidth) * 0.7,
          child: _buildZenStone(35, 25),
        ),
        Positioned(
          top: constraints.maxHeight * 0.6,
          right: _getResponsivePadding(constraints.maxWidth) * 0.5,
          child: _buildZenStone(25, 20),
        ),
      ],
    );
  }

  Widget _buildZenStone(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: ZenColors.stoneGray.withOpacity(0.1),
        borderRadius: BorderRadius.all(Radius.elliptical(width, height)),
        boxShadow: [
          BoxShadow(
            color: ZenColors.stoneGray.withOpacity(0.05),
            blurRadius: 8,
            spreadRadius: 2,
            offset: const Offset(2, 4),
          ),
        ],
      ),
    );
  }

  /// 📱 Conteúdo principal responsivo
  Widget _buildMainContent(AppLocalizations l10n, BoxConstraints constraints) {
    return SafeArea(
      child: AnimatedBuilder(
        animation: _mainController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: _buildScrollableContent(l10n, constraints),
              ),
            ),
          );
        },
      ),
    );
  }

  /// ✅ CORREÇÃO PRINCIPAL: Conteúdo scrollável responsivo
  Widget _buildScrollableContent(
      AppLocalizations l10n, BoxConstraints constraints) {
    final horizontalPadding = _getResponsivePadding(constraints.maxWidth);
    final verticalPadding =
        _getResponsiveVerticalPadding(constraints.maxHeight);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: constraints.maxHeight - (verticalPadding * 2),
          maxWidth: constraints.maxWidth - (horizontalPadding * 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ CORREÇÃO: Título sem texto japonês hardcoded
            _buildZenTitle(l10n, constraints),

            SizedBox(height: _getResponsiveSpacing(constraints.maxHeight, 48)),

            // Seção de Áudio
            _buildSettingsSection(
              title: l10n.audioSettings,
              subtitle: l10n.audioSettingsSubtitle,
              icon: Icons.volume_up_rounded,
              constraints: constraints,
              children: [
                _buildZenToggle(
                  label: l10n.gameSounds,
                  value: _soundEnabled,
                  onChanged: (value) =>
                      _updateSetting(() => _soundEnabled = value),
                  constraints: constraints,
                ),
                SizedBox(
                    height: _getResponsiveSpacing(constraints.maxHeight, 24)),
                _buildZenToggle(
                  label: l10n.backgroundMusic,
                  value: _musicEnabled,
                  onChanged: (value) =>
                      _updateSetting(() => _musicEnabled = value),
                  constraints: constraints,
                ),
                SizedBox(
                    height: _getResponsiveSpacing(constraints.maxHeight, 24)),
                _buildZenSlider(
                  label: l10n.musicVolume,
                  value: _musicVolume,
                  enabled: _musicEnabled,
                  onChanged: (value) =>
                      _updateSetting(() => _musicVolume = value),
                  constraints: constraints,
                ),
                SizedBox(
                    height: _getResponsiveSpacing(constraints.maxHeight, 24)),
                _buildZenSlider(
                  label: l10n.effectsVolume,
                  value: _sfxVolume,
                  enabled: _soundEnabled,
                  onChanged: (value) =>
                      _updateSetting(() => _sfxVolume = value),
                  constraints: constraints,
                ),
              ],
            ),

            SizedBox(height: _getResponsiveSpacing(constraints.maxHeight, 48)),

            // Seção de Experiência
            _buildSettingsSection(
              title: l10n.experienceSettings,
              subtitle: l10n.experienceSettingsSubtitle,
              icon: Icons.touch_app_rounded,
              constraints: constraints,
              children: [
                _buildZenToggle(
                  label: l10n.hapticFeedback,
                  value: _hapticsEnabled,
                  onChanged: (value) =>
                      _updateSetting(() => _hapticsEnabled = value),
                  constraints: constraints,
                ),
                SizedBox(
                    height: _getResponsiveSpacing(constraints.maxHeight, 24)),
                _buildZenToggle(
                  label: l10n.notifications,
                  value: _notificationsEnabled,
                  onChanged: (value) =>
                      _updateSetting(() => _notificationsEnabled = value),
                  constraints: constraints,
                ),
              ],
            ),

            SizedBox(height: _getResponsiveSpacing(constraints.maxHeight, 48)),

            // Seção de Personalização
            _buildSettingsSection(
              title: l10n.personalizationSettings,
              subtitle: l10n.personalizationSettingsSubtitle,
              icon: Icons.palette_rounded,
              constraints: constraints,
              children: [
                _buildLanguageDropdown(l10n, constraints),
                SizedBox(
                    height: _getResponsiveSpacing(constraints.maxHeight, 24)),
                _buildZenDropdown(
                  label: l10n.visualTheme,
                  value: _selectedTheme,
                  items: [
                    ('zen', l10n.themeClassicZen),
                    ('sakura', l10n.themeCherryBlossom),
                    ('bamboo', l10n.themeBamboo),
                  ],
                  onChanged: (value) =>
                      _updateSetting(() => _selectedTheme = value),
                  constraints: constraints,
                ),
              ],
            ),

            SizedBox(height: _getResponsiveSpacing(constraints.maxHeight, 48)),

            // Botões de ação
            _buildActionButtons(l10n, constraints),

            SizedBox(height: _getResponsiveSpacing(constraints.maxHeight, 24)),
          ],
        ),
      ),
    );
  }

  /// ✅ CORREÇÃO: Título sem texto japonês hardcoded
  Widget _buildZenTitle(AppLocalizations l10n, BoxConstraints constraints) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.settings,
          style: TextStyle(
            fontSize: _getResponsiveFontSize(constraints.maxWidth, 32),
            fontWeight: FontWeight.w300,
            color: ZenColors.inkBlack,
            letterSpacing: 4.0,
            height: 1.2,
          ),
        ),

        SizedBox(height: _getResponsiveSpacing(constraints.maxHeight, 16)),

        // Linha zen decorativa
        Container(
          width: _getResponsiveSize(constraints.maxWidth, 80),
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                ZenColors.bambooGreen.withOpacity(0.6),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// ✅ CORREÇÃO: Seção responsiva
  Widget _buildSettingsSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
    required BoxConstraints constraints,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(_getResponsivePadding(constraints.maxWidth)),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: ZenColors.mistWhite.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho da seção responsivo
          Row(
            children: [
              Container(
                padding:
                    EdgeInsets.all(_getResponsiveSize(constraints.maxWidth, 8)),
                decoration: BoxDecoration(
                  color: ZenColors.bambooGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: ZenColors.bambooGreen,
                  size: _getResponsiveSize(constraints.maxWidth, 24),
                ),
              ),
              SizedBox(width: _getResponsiveSpacing(constraints.maxWidth, 16)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize:
                            _getResponsiveFontSize(constraints.maxWidth, 20),
                        fontWeight: FontWeight.w500,
                        color: ZenColors.inkBlack,
                        letterSpacing: 1.0,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize:
                            _getResponsiveFontSize(constraints.maxWidth, 14),
                        fontWeight: FontWeight.w400,
                        color: ZenColors.stoneGray,
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: _getResponsiveSpacing(constraints.maxHeight, 24)),

          // Conteúdo da seção
          ...children,
        ],
      ),
    );
  }

  /// ✅ CORREÇÃO: Toggle responsivo
  Widget _buildZenToggle({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    required BoxConstraints constraints,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: _getResponsiveFontSize(constraints.maxWidth, 16),
              fontWeight: FontWeight.w500,
              color: ZenColors.inkBlack,
              letterSpacing: 0.5,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
        SizedBox(width: _getResponsiveSpacing(constraints.maxWidth, 16)),
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onChanged(!value);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: _getResponsiveSize(constraints.maxWidth, 56),
            height: _getResponsiveSize(constraints.maxWidth, 32),
            decoration: BoxDecoration(
              color: value
                  ? ZenColors.bambooGreen.withOpacity(0.8)
                  : ZenColors.stoneGray.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: (value ? ZenColors.bambooGreen : ZenColors.stoneGray)
                      .withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: _getResponsiveSize(constraints.maxWidth, 28),
                height: _getResponsiveSize(constraints.maxWidth, 28),
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      spreadRadius: 0,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// ✅ CORREÇÃO: Slider responsivo
  Widget _buildZenSlider({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
    required BoxConstraints constraints,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: _getResponsiveFontSize(constraints.maxWidth, 16),
                  fontWeight: FontWeight.w500,
                  color: enabled ? ZenColors.inkBlack : ZenColors.stoneGray,
                  letterSpacing: 0.5,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            Text(
              '${(value * 100).round()}%',
              style: TextStyle(
                fontSize: _getResponsiveFontSize(constraints.maxWidth, 14),
                fontWeight: FontWeight.w600,
                color: enabled ? ZenColors.bambooGreen : ZenColors.stoneGray,
              ),
            ),
          ],
        ),
        SizedBox(height: _getResponsiveSpacing(constraints.maxHeight, 12)),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: enabled
                ? ZenColors.bambooGreen.withOpacity(0.8)
                : ZenColors.stoneGray.withOpacity(0.3),
            inactiveTrackColor: ZenColors.mistWhite.withOpacity(0.5),
            thumbColor: enabled ? ZenColors.bambooGreen : ZenColors.stoneGray,
            overlayColor: ZenColors.bambooGreen.withOpacity(0.1),
            trackHeight: 4,
            thumbShape: RoundSliderThumbShape(
              enabledThumbRadius: _getResponsiveSize(constraints.maxWidth, 10),
            ),
          ),
          child: Slider(
            value: value,
            onChanged: enabled
                ? (newValue) {
                    HapticFeedback.selectionClick();
                    onChanged(newValue);
                  }
                : null,
            min: 0.0,
            max: 1.0,
          ),
        ),
      ],
    );
  }

  /// ✅ NOVO: Dropdown de idiomas com i18n
  Widget _buildLanguageDropdown(
      AppLocalizations l10n, BoxConstraints constraints) {
    final languageManager = context.watch<LanguageManager>();
    final availableLanguages = languageManager.getAvailableLanguages();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.language,
          style: TextStyle(
            fontSize: _getResponsiveFontSize(constraints.maxWidth, 16),
            fontWeight: FontWeight.w500,
            color: ZenColors.inkBlack,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: _getResponsiveSpacing(constraints.maxHeight, 12)),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: _getResponsiveSize(constraints.maxWidth, 16),
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: ZenColors.mistWhite.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: ZenColors.stoneGray.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedLanguage,
              onChanged: (newValue) async {
                if (newValue != null && newValue != _selectedLanguage) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _selectedLanguage = newValue;
                  });

                  // ✅ CORREÇÃO: Muda idioma dinamicamente
                  await languageManager.changeLanguage(newValue);
                }
              },
              items: availableLanguages.map((language) {
                return DropdownMenuItem<String>(
                  value: language.code,
                  child: Text(
                    language.name,
                    style: TextStyle(
                      fontSize:
                          _getResponsiveFontSize(constraints.maxWidth, 16),
                      color: ZenColors.inkBlack,
                    ),
                  ),
                );
              }).toList(),
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: ZenColors.stoneGray,
                size: _getResponsiveSize(constraints.maxWidth, 24),
              ),
              dropdownColor: Colors.white,
              isExpanded: true,
            ),
          ),
        ),
      ],
    );
  }

  /// ✅ CORREÇÃO: Dropdown responsivo
  Widget _buildZenDropdown({
    required String label,
    required String value,
    required List<(String, String)> items,
    required ValueChanged<String> onChanged,
    required BoxConstraints constraints,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: _getResponsiveFontSize(constraints.maxWidth, 16),
            fontWeight: FontWeight.w500,
            color: ZenColors.inkBlack,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: _getResponsiveSpacing(constraints.maxHeight, 12)),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: _getResponsiveSize(constraints.maxWidth, 16),
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: ZenColors.mistWhite.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: ZenColors.stoneGray.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              onChanged: (newValue) {
                if (newValue != null) {
                  HapticFeedback.selectionClick();
                  onChanged(newValue);
                }
              },
              items: items.map((item) {
                return DropdownMenuItem<String>(
                  value: item.$1,
                  child: Text(
                    item.$2,
                    style: TextStyle(
                      fontSize:
                          _getResponsiveFontSize(constraints.maxWidth, 16),
                      color: ZenColors.inkBlack,
                    ),
                  ),
                );
              }).toList(),
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: ZenColors.stoneGray,
                size: _getResponsiveSize(constraints.maxWidth, 24),
              ),
              dropdownColor: Colors.white,
              isExpanded: true,
            ),
          ),
        ),
      ],
    );
  }

  /// ✅ CORREÇÃO: Botões responsivos
  Widget _buildActionButtons(
      AppLocalizations l10n, BoxConstraints constraints) {
    return Row(
      children: [
        Expanded(
          child: _buildZenButton(
            label: l10n.restoreDefaults,
            icon: Icons.refresh_rounded,
            isPrimary: false,
            onPressed: _resetToDefaults,
            constraints: constraints,
          ),
        ),
        SizedBox(width: _getResponsiveSpacing(constraints.maxWidth, 16)),
        Expanded(
          child: _buildZenButton(
            label: l10n.save,
            icon: Icons.check_rounded,
            isPrimary: true,
            onPressed: () => _saveSettings(l10n),
            constraints: constraints,
          ),
        ),
      ],
    );
  }

  Widget _buildZenButton({
    required String label,
    required IconData icon,
    required bool isPrimary,
    required VoidCallback onPressed,
    required BoxConstraints constraints,
  }) {
    return Container(
      height: _getResponsiveSize(constraints.maxHeight, 52),
      decoration: BoxDecoration(
        gradient: isPrimary
            ? LinearGradient(
                colors: [
                  ZenColors.bambooGreen,
                  ZenColors.bambooGreen.withOpacity(0.8),
                ],
              )
            : null,
        color: isPrimary ? null : Colors.transparent,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isPrimary
              ? ZenColors.bambooGreen
              : ZenColors.stoneGray.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: ZenColors.bambooGreen.withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: () {
            HapticFeedback.mediumImpact();
            onPressed();
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isPrimary ? Colors.white : ZenColors.stoneGray,
                size: _getResponsiveSize(constraints.maxWidth, 20),
              ),
              SizedBox(width: _getResponsiveSpacing(constraints.maxWidth, 8)),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isPrimary ? Colors.white : ZenColors.stoneGray,
                    fontSize: _getResponsiveFontSize(constraints.maxWidth, 16),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ✅ CORREÇÃO: Barra de navegação responsiva
  Widget _buildNavigationBar(
      AppLocalizations l10n, BoxConstraints constraints) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: _getResponsiveSize(constraints.maxWidth, 16),
            vertical: 8,
          ),
          child: Row(
            children: [
              _buildNavButton(
                icon: Icons.arrow_back_ios_rounded,
                onPressed: () => Navigator.of(context).pop(),
                constraints: constraints,
              ),
              const Spacer(),
              
              const Spacer(),
              SizedBox(width: _getResponsiveSize(constraints.maxWidth, 40)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required VoidCallback onPressed,
    required BoxConstraints constraints,
  }) {
    final size = _getResponsiveSize(constraints.maxWidth, 40);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(size / 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(size / 2),
          onTap: () {
            HapticFeedback.selectionClick();
            onPressed();
          },
          child: Icon(
            icon,
            size: _getResponsiveSize(constraints.maxWidth, 20),
            color: ZenColors.inkBlack,
          ),
        ),
      ),
    );
  }

  /// ✅ MÉTODOS RESPONSIVOS

  double _getResponsivePadding(double availableWidth) {
    if (availableWidth < 350) return 16.0;
    if (availableWidth < 500) return 20.0;
    if (availableWidth < 700) return 24.0;
    return 28.0;
  }

  double _getResponsiveVerticalPadding(double availableHeight) {
    if (availableHeight < 600) return 60.0;
    if (availableHeight < 800) return 70.0;
    return 80.0;
  }

  double _getResponsiveFontSize(double availableWidth, double baseSize) {
    if (availableWidth < 350) return baseSize * 0.8;
    if (availableWidth < 500) return baseSize * 0.9;
    if (availableWidth > 800) return baseSize * 1.1;
    return baseSize;
  }

  double _getResponsiveSize(double availableSpace, double baseSize) {
    if (availableSpace < 350) return baseSize * 0.8;
    if (availableSpace < 500) return baseSize * 0.9;
    if (availableSpace > 800) return baseSize * 1.1;
    return baseSize;
  }

  double _getResponsiveSpacing(double availableSpace, double baseSpacing) {
    if (availableSpace < 350) return baseSpacing * 0.7;
    if (availableSpace < 500) return baseSpacing * 0.85;
    if (availableSpace > 800) return baseSpacing * 1.2;
    return baseSpacing;
  }

  /// ⚙️ Métodos de controle

  void _updateSetting(VoidCallback update) {
    setState(update);
    HapticFeedback.selectionClick();
  }

  void _resetToDefaults() {
    setState(() {
      _soundEnabled = true;
      _musicEnabled = true;
      _hapticsEnabled = true;
      _notificationsEnabled = true;
      _musicVolume = 0.7;
      _sfxVolume = 0.8;
      _selectedLanguage = 'pt';
      _selectedTheme = 'zen';
    });

    // Reset idioma para português
    context.read<LanguageManager>().resetToDefault();

    HapticFeedback.mediumImpact();
    final l10n = AppLocalizations.of(context)!;
    _showZenSnackBar(l10n.settingsRestored);
  }

  void _saveSettings(AppLocalizations l10n) async {
    final gameState = context.read<GameStateManager>();

    await gameState.updateSettings(
      sound: _soundEnabled,
      music: _musicEnabled,
      haptics: _hapticsEnabled,
    );

    HapticFeedback.heavyImpact();
    _showZenSnackBar(l10n.settingsSaved);
  }

  void _showZenSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: ZenColors.bambooGreen.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

/// 🎨 Painter para textura de areia rastejada
class SandTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ZenColors.sandBeige.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (int i = 0; i < 12; i++) {
      final y = size.height * 0.1 + (i * size.height * 0.08);
      final path = Path();

      path.moveTo(0, y);
      for (double x = 0; x <= size.width; x += 15) {
        final waveY = y + math.sin(x * 0.015) * 3;
        path.lineTo(x, waveY);
      }

      canvas.drawPath(path, paint);
    }

    final centerPaint = Paint()
      ..color = ZenColors.stoneGray.withOpacity(0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final center = Offset(size.width * 0.8, size.height * 0.2);
    for (int i = 1; i <= 5; i++) {
      canvas.drawCircle(center, i * 20.0, centerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 🌊 Painter para ondulações de água
class WaterRipplePainter extends CustomPainter {
  final double animationValue;

  WaterRipplePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ZenColors.waterBlue.withOpacity(0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final center1 = Offset(size.width * 0.3, size.height * 0.6);
    final center2 = Offset(size.width * 0.7, size.height * 0.4);

    for (int i = 0; i < 4; i++) {
      final progress = (animationValue + (i * 0.25)) % 1.0;
      final radius = 80 * progress;
      final opacity = (1.0 - progress) * 0.4;

      paint.color = ZenColors.waterBlue.withOpacity(opacity);
      canvas.drawCircle(center1, radius, paint);
      canvas.drawCircle(center2, radius * 0.8, paint);
    }
  }

  @override
  bool shouldRepaint(covariant WaterRipplePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

/// 🎨 Paleta de cores zen
class ZenColors {
  static const Color inkBlack = Color(0xFF2C2C2C);
  static const Color stoneGray = Color(0xFF8E8E8E);
  static const Color bambooGreen = Color(0xFF7CB342);
  static const Color cherryBlossom = Color(0xFFFFB7C5);
  static const Color bambooLeaf = Color(0xFF9CCC65);
  static const Color waterBlue = Color(0xFF81C784);
  static const Color sandBeige = Color(0xFFF5F5DC);
  static const Color mistWhite = Color(0xFFF8F8F8);
}

/// 🌅 Gradientes zen
class ZenGradients {
  static const LinearGradient settingsBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFAFAFA),
      Color(0xFFF0F8F0),
      Color(0xFFFFF8DC),
      Color(0xFFF5F5F5),
    ],
    stops: [0.0, 0.3, 0.7, 1.0],
  );
}
