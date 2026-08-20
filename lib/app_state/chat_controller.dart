import 'package:flutter/foundation.dart';

import 'chatbot_tools.dart';

/// One message in the camera chatbot's conversation — either the user's own
/// text, or an assistant reply plus any real tool-call side effects
/// (snapshot/live-view/scan-results/confirm cards) it produced.
class ChatMessage {
  const ChatMessage.user(this.text) : isUser = true, effects = const [];

  const ChatMessage.assistant(this.text, {this.effects = const []})
    : isUser = false;

  final bool isUser;
  final String text;
  final List<ChatToolEffect> effects;
}

/// Owns the camera chatbot's conversation history for the lifetime of the
/// app process — instantiated once in `main.dart` alongside the other
/// `ValueNotifier` controllers, not by `_CameraChatbotSheet` itself.
///
/// The chat overlay (`camera_chatbot.dart`) is a `showModalBottomSheet`, so
/// its own `State` is destroyed every time it's closed (including an
/// accidental back-gesture dismiss) — a `_messages` list living in that
/// State was wiped on every close/reopen, which read as "the chatbot lost
/// my conversation" even though nothing actually went wrong. Living here
/// instead, `_messages` survives any number of close/reopens within the
/// same app session; it only resets on a real app restart (nothing here is
/// persisted to disk).
class ChatController extends ValueNotifier<List<ChatMessage>> {
  ChatController() : super(const []);

  void addUserMessage(String text) {
    value = [...value, ChatMessage.user(text)];
  }

  void addAssistantMessage(
    String text, {
    List<ChatToolEffect> effects = const [],
  }) {
    value = [...value, ChatMessage.assistant(text, effects: effects)];
  }

  /// Replaces the message at [index] — used while streaming a reply
  /// token-by-token, and to attach a tool-call effect as it arrives.
  void updateAt(int index, ChatMessage message) {
    final updated = [...value];
    updated[index] = message;
    value = updated;
  }

  /// [ConfirmEffect] instances the user has already acted on (Confirm or
  /// Cancel) — tracked here rather than in the chat sheet's own `State` so
  /// a destructive action already handled doesn't show live Confirm/Cancel
  /// buttons again (and become re-triggerable) after the chat is closed
  /// and reopened; the effect object itself persists in [value] either way
  /// since it's part of a `ChatMessage`, so this Set needs the same
  /// process lifetime.
  final Set<ConfirmEffect> resolvedConfirmations = {};

  /// [ConfirmEffect]s whose real `camera_api` call (`onConfirm()`) is
  /// currently in flight — distinct from [resolvedConfirmations] so the
  /// card can show a busy spinner instead of jumping straight to "Handled"
  /// before the actual reboot/reset/delete has finished.
  final Set<ConfirmEffect> inProgressConfirmations = {};

  void markConfirmationInProgress(ConfirmEffect effect) {
    inProgressConfirmations.add(effect);
    notifyListeners();
  }

  void markConfirmationResolved(ConfirmEffect effect) {
    inProgressConfirmations.remove(effect);
    resolvedConfirmations.add(effect);
    notifyListeners();
  }
}
