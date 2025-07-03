import 'package:flutter/material.dart';

/// 🎭 Transições de página suaves e zen
class SmoothPageTransitions {
  
  /// Transição de slide zen (da direita para esquerda)
  static PageRouteBuilder<T> slideFromRight<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeOutQuart;

        final tween = Tween(begin: begin, end: end);
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: curve,
        );

        return SlideTransition(
          position: tween.animate(curvedAnimation),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 600),
      reverseTransitionDuration: const Duration(milliseconds: 400),
    );
  }

  /// Transição de fade zen
  static PageRouteBuilder<T> fadeTransition<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 500),
      reverseTransitionDuration: const Duration(milliseconds: 300),
    );
  }

  /// Transição de scale zen (crescimento suave)
  static PageRouteBuilder<T> scaleTransition<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.easeOutBack;
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: curve,
        );

        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.8,
            end: 1.0,
          ).animate(curvedAnimation),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 700),
      reverseTransitionDuration: const Duration(milliseconds: 400),
    );
  }

  /// Transição zen combinada (slide + fade + scale)
  static PageRouteBuilder<T> zenTransition<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Animação de slide
        final slideAnimation = Tween<Offset>(
          begin: const Offset(0.3, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.8, curve: Curves.easeOutQuart),
        ));

        // Animação de fade
        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
        ));

        // Animação de scale
        final scaleAnimation = Tween<double>(
          begin: 0.9,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: const Interval(0.2, 1.0, curve: Curves.easeOutBack),
        ));

        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: ScaleTransition(
              scale: scaleAnimation,
              child: child,
            ),
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 800),
      reverseTransitionDuration: const Duration(milliseconds: 500),
    );
  }

  /// Transição de ripple zen (efeito de ondulação)
  static PageRouteBuilder<T> rippleTransition<T>(
    Widget page, {
    Offset? center,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return ClipPath(
          clipper: CircleRevealClipper(
            fraction: animation.value,
            center: center,
          ),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 600),
      reverseTransitionDuration: const Duration(milliseconds: 400),
    );
  }

  /// Transição de rotação zen (3D flip)
  static PageRouteBuilder<T> flipTransition<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final rotationAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        ));

        return AnimatedBuilder(
          animation: rotationAnimation,
          builder: (context, child) {
            if (rotationAnimation.value <= 0.5) {
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(rotationAnimation.value * 3.14159),
                child: Container(), // Página anterior (vazia)
              );
            } else {
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY((1 - rotationAnimation.value) * 3.14159),
                child: child,
              );
            }
          },
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 800),
      reverseTransitionDuration: const Duration(milliseconds: 600),
    );
  }
}

/// 🎨 Clipper para transição de ripple
class CircleRevealClipper extends CustomClipper<Path> {
  final double fraction;
  final Offset? center;

  CircleRevealClipper({
    required this.fraction,
    this.center,
  });

  @override
  Path getClip(Size size) {
    final Offset circleCenter = center ?? Offset(size.width / 2, size.height / 2);
    final double maxRadius = (size.width > size.height ? size.width : size.height) * 1.2;
    final double radius = maxRadius * fraction;

    return Path()..addOval(Rect.fromCircle(center: circleCenter, radius: radius));
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}

/// 🌊 Extensões para navegação zen
extension ZenNavigation on NavigatorState {
  
  /// Push com transição zen
  Future<T?> pushZen<T>(Widget page) {
    return push<T>(SmoothPageTransitions.zenTransition<T>(page));
  }

  /// Push replacement com transição zen
  Future<T?> pushReplacementZen<T>(Widget page) {
    return pushReplacement<T, dynamic>(SmoothPageTransitions.zenTransition<T>(page));
  }

  /// Push com slide suave
  Future<T?> pushSlide<T>(Widget page) {
    return push<T>(SmoothPageTransitions.slideFromRight<T>(page));
  }

  /// Push com fade suave
  Future<T?> pushFade<T>(Widget page) {
    return push<T>(SmoothPageTransitions.fadeTransition<T>(page));
  }

  /// Push com scale suave
  Future<T?> pushScale<T>(Widget page) {
    return push<T>(SmoothPageTransitions.scaleTransition<T>(page));
  }

  /// Push com ripple effect
  Future<T?> pushRipple<T>(Widget page, {Offset? center}) {
    return push<T>(SmoothPageTransitions.rippleTransition<T>(page, center: center));
  }

  /// Push com flip 3D
  Future<T?> pushFlip<T>(Widget page) {
    return push<T>(SmoothPageTransitions.flipTransition<T>(page));
  }
}

/// 🎯 Helper para transições contextuais
class ZenTransitionHelper {
  
  /// Escolhe a melhor transição baseada no contexto
  static PageRouteBuilder<T> contextualTransition<T>(
    Widget page, {
    required String fromRoute,
    required String toRoute,
  }) {
    // Menu para jogo: Scale transition
    if (fromRoute.contains('menu') && toRoute.contains('game')) {
      return SmoothPageTransitions.scaleTransition<T>(page);
    }
    
    // Jogo para vitória: Zen transition
    if (fromRoute.contains('game') && toRoute.contains('victory')) {
      return SmoothPageTransitions.zenTransition<T>(page);
    }
    
    // Vitória para próximo nível: Slide transition
    if (fromRoute.contains('victory') && toRoute.contains('game')) {
      return SmoothPageTransitions.slideFromRight<T>(page);
    }
    
    // Qualquer para menu: Fade transition
    if (toRoute.contains('menu')) {
      return SmoothPageTransitions.fadeTransition<T>(page);
    }
    
    // Padrão: Zen transition
    return SmoothPageTransitions.zenTransition<T>(page);
  }
}