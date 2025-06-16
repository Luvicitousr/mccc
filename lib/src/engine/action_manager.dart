// lib/src/engine/action_manager.dart
import 'dart:collection';

enum ActionState {
  idle,
  running,
  terminated,
}

/// Represents an abstract action in the game.
abstract class Action {
  /// State of the action.
  ActionState state = ActionState.idle;

  /// Method called before starting the action.
  void onStart(Map<String, dynamic> globals) {}

  /// Performs the action or a part of the action.
  void perform(
      ListQueue<Action> actionQueue, Map<String, dynamic> globals);

  /// Returns the "terminated" status of the action.
  bool get isTerminated => state == ActionState.terminated;

  /// Declares the action as terminated.
  void terminate() {
    state = ActionState.terminated;
  }
}

/// Class to manage the game's action queue.
class ActionManager {
  /// Action queue.
  late ListQueue<Action> queue;

  /// Global variables.
  late Map<String, dynamic> globals;

  ActionManager() {
    queue = ListQueue<Action>();
    globals = {};
  }

  /// Performs the current action.
  void performStuff() {
    if (queue.isNotEmpty) {
      Action top = queue.first;
      if (top.state == ActionState.idle) {
        top.state = ActionState.running;
        top.onStart(globals);
      }
      top.perform(queue, globals);
      if (top.isTerminated) {
        queue.removeFirst();
      }
    }
  }

  /// Adds a new action to the action queue
  /// and allows for action chaining by returning the current element.
  ActionManager push(Action action) {
    queue.add(action);
    return this;
  }

  /// Returns true if actions are still in progress.
  bool isRunning() {
    return queue.isNotEmpty;
  }
}