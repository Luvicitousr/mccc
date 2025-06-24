import 'dart:collection'; // <-- GARANTA QUE ESTA LINHA EXISTA
import '../engine/action_manager.dart';

/// Uma ação que executa uma função de callback e termina imediatamente.
class FunctionAction extends Action {
  final Function _function;

  FunctionAction(this._function);

  @override
  void perform(ListQueue<Action> actionQueue, Map<String, dynamic> globals) {
    _function();
    terminate(); // A ação termina assim que a função é executada
  }
}
