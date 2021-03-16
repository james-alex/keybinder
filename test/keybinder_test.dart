import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keybinder/keybinder.dart';
import 'package:list_utilities/list_utilities.dart';

void main() {
  testWidgets('Keybinder', (_) async {
    final pressed = <Keybinding?, int>{null: 0};
    final released = <Keybinding?, int>{};

    Keybinder.bind(
        Keybinding.empty(), () => pressed[null] = pressed[null]! + 1);
    var empty = 0;

    late Completer<void> completer;
    late Future<void> onComplete;
    Keybinding? lastKeybinding;

    for (var i = 0; i < _keys.length; i++) {
      // Create a keybinding from a combination of 1-4 keys.
      final keys = List<LogicalKeyboardKey>.generate(
          ((i % 3) + 1).clamp(0, _keys.length), (_) => _keys.removeRandom());
      final keybinding =
          Keybinding.from(keys, inclusive: lastKeybinding != null);

      // Add the keybinding to the pressed/released count maps.
      pressed.addAll({keybinding: 0});
      released.addAll({keybinding: 0});

      // Register the keybinding with all 3 types of callbacks.
      void onPressed() => pressed[keybinding] = pressed[keybinding]! + 1;
      Keybinder.bind(keybinding, onPressed);

      void onToggle(bool isPressed) => isPressed
          ? pressed[keybinding] = pressed[keybinding]! + 1
          : released[keybinding] = released[keybinding]! + 1;
      Keybinder.bind(keybinding, onToggle);

      void onKeyToggled(Keybinding keybinding, bool isPressed) => isPressed
          ? pressed[keybinding] = pressed[keybinding]! + 1
          : released[keybinding] = released[keybinding]! + 1;
      Keybinder.bind(keybinding, onKeyToggled);

      // Bind a callback to complete a completer after
      // the other callbacks have been called.
      Keybinder.bind(keybinding, (pressed) {
        if (!completer.isCompleted) completer.complete();
      });

      completer = Completer<void>();
      onComplete = completer.future;

      // Press the keys mapped to the keybinding.
      for (var key in keys) {
        await simulateKeyDownEvent(key);
      }

      // Wait for the callbacks to be called.
      await onComplete;

      expect(pressed[keybinding], equals(3));
      expect(released[keybinding], equals(0));

      if (lastKeybinding != null) {
        expect(pressed[lastKeybinding], equals(3));
        expect(released[lastKeybinding], equals(2));
      }

      if (lastKeybinding == null) {
        // If the keybinding is exclusive, keep the keys
        // held down until the next iteration.
        lastKeybinding = keybinding;
      } else {
        // If the keybinding is inclusive...
        completer = Completer<void>();
        onComplete = completer.future;

        // Release the current iteration's keys.
        for (var key in keys) {
          await simulateKeyUpEvent(key);
        }

        await onComplete;

        expect(pressed[keybinding], equals(3));
        expect(released[keybinding], equals(2));

        expect(pressed[lastKeybinding], equals(6));
        expect(released[lastKeybinding], equals(2));

        // Release the last iteration's keys.
        completer = Completer<void>();
        onComplete = completer.future;

        final lastKeybindingKeys = lastKeybinding.keyCodes
            .map<LogicalKeyboardKey>((keyCode) =>
                LogicalKeyboardKey.findKeyByKeyId(keyCode.keyIds.first)!);
        for (var key in lastKeybindingKeys) {
          await simulateKeyUpEvent(key);
        }

        await onComplete;

        expect(pressed[lastKeybinding], equals(6));
        expect(released[lastKeybinding], equals(4));

        // Remove the keybindings and verify they're no longer active.
        expect(Keybinder.isActive(keybinding), equals(true));
        Keybinder.remove(keybinding);
        expect(Keybinder.isActive(keybinding), equals(false));

        expect(Keybinder.isActive(lastKeybinding), equals(true));
        Keybinder.remove(lastKeybinding);
        expect(Keybinder.isActive(lastKeybinding), equals(false));
        lastKeybinding = null;

        expect(pressed[null], equals(empty += 1));
      }

      i += i % 3;
    }

    expect(Keybinder.isActive(Keybinding.empty()), equals(true));
    Keybinder.dispose();
    expect(Keybinder.isActive(Keybinding.empty()), equals(false));
  });

  // Verify that the [KeyCode] constants' [keyIds] haven't
  // been updated in the Flutter source code.
  test('KeyCode Constants', () {
    // alt
    expect(
        KeyCode.alt.keyIds,
        equals({
          LogicalKeyboardKey.altLeft.keyId,
          LogicalKeyboardKey.altRight.keyId
        }));
    // ctrl
    expect(
        KeyCode.ctrl.keyIds,
        equals({
          LogicalKeyboardKey.controlLeft.keyId,
          LogicalKeyboardKey.controlRight.keyId
        }));
    // shift
    expect(
        KeyCode.shift.keyIds,
        equals({
          LogicalKeyboardKey.shiftLeft.keyId,
          LogicalKeyboardKey.shiftRight.keyId
        }));
  });
}

final _keys = <LogicalKeyboardKey>[
  LogicalKeyboardKey.altLeft,
  LogicalKeyboardKey.altRight,
  LogicalKeyboardKey.arrowDown,
  LogicalKeyboardKey.backquote,
  LogicalKeyboardKey.backslash,
  LogicalKeyboardKey.backspace,
  LogicalKeyboardKey.bracketLeft,
  LogicalKeyboardKey.bracketRight,
  LogicalKeyboardKey.capsLock,
  LogicalKeyboardKey.comma,
  LogicalKeyboardKey.controlLeft,
  LogicalKeyboardKey.controlRight,
  LogicalKeyboardKey.delete,
  LogicalKeyboardKey.enter,
  LogicalKeyboardKey.equal,
  LogicalKeyboardKey.escape,
  LogicalKeyboardKey.f1,
  LogicalKeyboardKey.f2,
  LogicalKeyboardKey.f3,
  LogicalKeyboardKey.f4,
  LogicalKeyboardKey.f5,
  LogicalKeyboardKey.f6,
  LogicalKeyboardKey.f7,
  LogicalKeyboardKey.f8,
  LogicalKeyboardKey.f9,
  LogicalKeyboardKey.f10,
  LogicalKeyboardKey.f11,
  LogicalKeyboardKey.f12,
  LogicalKeyboardKey.f13,
  LogicalKeyboardKey.f14,
  LogicalKeyboardKey.f15,
  LogicalKeyboardKey.f16,
  LogicalKeyboardKey.f17,
  LogicalKeyboardKey.f18,
  LogicalKeyboardKey.f19,
  LogicalKeyboardKey.f20,
  LogicalKeyboardKey.f21,
  LogicalKeyboardKey.f22,
  LogicalKeyboardKey.f23,
  LogicalKeyboardKey.f24,
  LogicalKeyboardKey.insert,
  LogicalKeyboardKey.keyA,
  LogicalKeyboardKey.keyB,
  LogicalKeyboardKey.keyC,
  LogicalKeyboardKey.keyD,
  LogicalKeyboardKey.keyE,
  LogicalKeyboardKey.keyF,
  LogicalKeyboardKey.keyG,
  LogicalKeyboardKey.keyH,
  LogicalKeyboardKey.keyI,
  LogicalKeyboardKey.keyJ,
  LogicalKeyboardKey.keyK,
  LogicalKeyboardKey.keyL,
  LogicalKeyboardKey.keyM,
  LogicalKeyboardKey.keyN,
  LogicalKeyboardKey.keyO,
  LogicalKeyboardKey.keyP,
  LogicalKeyboardKey.keyQ,
  LogicalKeyboardKey.keyR,
  LogicalKeyboardKey.keyS,
  LogicalKeyboardKey.keyT,
  LogicalKeyboardKey.keyU,
  LogicalKeyboardKey.keyV,
  LogicalKeyboardKey.keyW,
  LogicalKeyboardKey.keyX,
  LogicalKeyboardKey.keyY,
  LogicalKeyboardKey.keyZ,
  LogicalKeyboardKey.minus,
  LogicalKeyboardKey.numpad0,
  LogicalKeyboardKey.numpad1,
  LogicalKeyboardKey.numpad2,
  LogicalKeyboardKey.numpad3,
  LogicalKeyboardKey.numpad4,
  LogicalKeyboardKey.numpad5,
  LogicalKeyboardKey.numpad6,
  LogicalKeyboardKey.numpad7,
  LogicalKeyboardKey.numpad8,
  LogicalKeyboardKey.numpad9,
  LogicalKeyboardKey.numpadAdd,
  LogicalKeyboardKey.numpadDecimal,
  LogicalKeyboardKey.numpadDivide,
  LogicalKeyboardKey.numpadMultiply,
  LogicalKeyboardKey.numpadSubtract,
  LogicalKeyboardKey.period,
  LogicalKeyboardKey.quote,
  LogicalKeyboardKey.semicolon,
  LogicalKeyboardKey.shiftLeft,
  LogicalKeyboardKey.shiftRight,
  LogicalKeyboardKey.space,
  LogicalKeyboardKey.tab,
];
