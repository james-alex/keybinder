import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:list_utilities/list_utilities.dart';

/// A utility class used to bind callbacks to a combination
/// of one or more physical keys on a keyboard; utilizing the
/// global [RawKeyboard] instance.
class Keybinder {
  Keybinder._();

  /// A reference to the global [RawKeyboard] instance.
  ///
  /// If `null`, it's assumed a listener hasn't been added.
  static RawKeyboard _rawKeyboard;

  /// Every [Keybinding]s registered to [Keybinder] and their associated callbacks.
  static final _keybindings = <Keybinding, List<Function>>{};

  /// The [Keybinding]s that are currently being pressed.
  static final _activeKeybindings = <Keybinding>{};

  /// Adds the listener that handles all registered
  /// callbacks to the [RawKeyboard] instance.
  static void _init() {
    _rawKeyboard = RawKeyboard.instance..addListener(_listener);
  }

  /// The listener provided to the [RawKeyboard] instance.
  static void _listener(RawKeyEvent event) {
    // If any of the registered [Keybinding]s are no longer being pressed,
    // notify their listeners.
    _activeKeybindings.removeWhere((keybinding) {
      if (keybinding.isPressed) {
        return false;
      }

      for (var callback in _keybindings[keybinding]) {
        if (callback is KeybindingEvent) {
          callback(keybinding, false);
        } else if (callback is ValueChanged<bool>) {
          callback(false);
        }
      }

      return true;
    });

    // If any of the registered [Keybinding]s are being pressed,
    // notify their listeners.
    for (var keybinding in _keybindings.keys) {
      if (keybinding.isPressed && !_activeKeybindings.contains(keybinding)) {
        for (var callback in _keybindings[keybinding]) {
          if (callback is KeybindingEvent) {
            callback(keybinding, true);
          } else if (callback is ValueChanged<bool>) {
            callback(true);
          } else {
            callback();
          }
        }
        _activeKeybindings.add(keybinding);
      }
    }
  }

  /// Returns `true` if the [keybinding] is bound to any callbacks.
  static bool isActive(Keybinding keybinding) {
    assert(keybinding != null);
    return _keybindings.containsKey(keybinding);
  }

  /// Binds the [callback] to [keybinding] in the [Keybinder].
  ///
  /// [callback] can be provided as a [Function] without a parameter,
  /// as a `ValueChanged<bool>` callback (a function with a single
  /// boolean parameter,) or as a [KeybindingEvent], which has a
  /// [Keybinding] parameter and a boolean parameter:
  /// `void Function(Keybinding keybinding, bool pressed)`.
  static void bind(Keybinding keybinding, Function callback) {
    assert(keybinding != null);
    assert(
        callback != null &&
            (callback is VoidCallback ||
                callback is ValueChanged<bool> ||
                callback is KeybindingEvent),
        '[callback] must be a [VoidCallback], `ValueChanged<bool>`, '
        'or a [KeybindingEvent].');

    // Initialize the [RawKeyboard] listener, if it hasn't already been.
    if (_rawKeyboard == null) _init();

    // Add the callback to the [_keybindings] map.
    if (_keybindings.containsKey(keybinding)) {
      _keybindings[keybinding].add(callback);
    } else {
      _keybindings.addAll({
        keybinding: [callback],
      });
    }
  }

  /// Removes the callback(s) associated with [keybinding] from [Keybinder].
  ///
  /// If a [callback] was provided, only that callback will be removed,
  /// otherwise if [callback] is `null`, every callback bound to [keybinding]
  /// will be removed.
  ///
  /// Returns `false` if the [keybinding] isn't bound to any callbacks,
  /// of if [callback] was provided, but wasn't bound to [keybinding],
  /// otherwise returns `true`.
  static bool remove(Keybinding keybinding, [Function callback]) {
    assert(keybinding != null);

    if (!_keybindings.containsKey(keybinding)) {
      return false;
    }

    // If a callback wasn't provided, remove the [keybinding]
    // along with every callback bound to it.
    if (callback == null) {
      _keybindings.remove(keybinding);
      return true;
    }

    final wasRemoved = _keybindings[keybinding].remove(callback);

    // If there are no longer any callbacks registered to [keybinding],
    // remove it from the map.
    if (wasRemoved && _keybindings[keybinding].isEmpty) {
      _keybindings.remove(keybinding);
    }

    return wasRemoved;
  }

  /// Removes all registered callbacks from [Keybinder] and removes
  /// [Keybinder]'s listener from the [RawKeyboard] instance.
  ///
  /// __Note:__ A new listener will be added to the [RawKeyboard]
  /// instance if another [Keybinding] is [register]ed.
  static void dispose() {
    _keybindings.clear();
    _rawKeyboard.removeListener(_listener);
    _rawKeyboard = null;
  }
}

/// A callback that can be bound to a [Keybinding].
///
/// __Note:__ [`void Function(bool pressed)`] callbacks and callbacks
/// without parameters can also be bound to [Keybinding]s.
typedef KeybindingEvent = void Function(Keybinding keybinding, bool pressed);

/// {@template keybinder.Keybinding}
///
/// A set of [KeyCode]s used to bind callbacks to a combination
/// of zero or more keys on a keyboard. __See:__ [Keybinder]
///
/// {@endtemplate}
class Keybinding {
  /// {@macro keybinder.Keybinding}
  ///
  /// [keyCodes] must not be `null`, but may be empty.
  ///
  /// If [inclusive] is `true`, the [Keybinding] will be considered
  /// pressed if all of its [keyCodes] are currently pressed on the
  /// keyboard, regardless of whether any additional keys are pressed,
  /// as well. If `false`, the [Keybinding] will only be considered
  /// pressed if its [keyCodes] are the only keys currently pressed.
  ///
  /// __Note:__ Empty [Keybinding]s are only triggered when no other keys
  /// are pressed, regardless of whether [inclusive] is `true` or not.
  const Keybinding(this.keyCodes, {this.inclusive = false, this.debugLabel})
      : assert(keyCodes != null),
        assert(inclusive != null);

  /// Creates a [Keybinding] mapped to no keys.
  factory Keybinding.empty() => Keybinding([]);

  /// Creates a new [Keybinding] from [LogicalKeyboardKey]s.
  factory Keybinding.from(
    Iterable<LogicalKeyboardKey> keys, {
    bool inclusive = false,
  }) {
    assert(keys != null);
    assert(inclusive != null);
    return Keybinding(keys.map<KeyCode>((key) => KeyCode({key.keyId})).toList(),
        inclusive: inclusive);
  }

  /// The [KeyCode]s that make up the keybinding.
  final Iterable<KeyCode> keyCodes;

  /// If `true`, this keybinding will be activated when all of its keys
  /// are pressed, even if other keys have been pressed in addition.
  ///
  /// If `false`, this keybinding will only be activated when all of its
  /// keys are pressed and no additional keys have been pressed.
  final bool inclusive;

  /// An optional label for debugging purposes; used by the [toString] method.
  final String debugLabel;

  /// Returns `true` if this keybinding includes [keyCode].
  bool contains(KeyCode keyCode) => keyCodes.any((key) => key.equals(keyCode));

  /// Returns `true` if this keybinding is mapped to no keys.
  bool get isEmpty => keyCodes.isEmpty;

  /// Returns `true` if this keybinding has any keys mapped to it.
  bool get isNotEmpty => keyCodes.isNotEmpty;

  /// Returns `true` if the keys currently pressed match this keybinding.
  bool get isPressed {
    final keysPressed = RawKeyboard.instance.keysPressed;

    if (isEmpty) {
      if (keysPressed.isEmpty) {
        return true;
      }
    } else if (inclusive) {
      if (keyCodes.every((keyCode) => keysPressed
          .map<int>((key) => key.keyId)
          .any((keyId) => keyCode.keyIds.contains(keyId)))) {
        return true;
      }
    } else if (equals(Keybinding.from(keysPressed))) {
      return true;
    }

    return false;
  }

  /// A keybinding that registers as either `alt` key.
  static const alt = Keybinding([KeyCode.alt], debugLabel: 'alt');

  /// A keybinding that registers as either `ctrl` key.
  static const ctrl = Keybinding([KeyCode.ctrl], debugLabel: 'ctrl');

  /// A keybinding that registers as either `shift` key.
  static const shift = Keybinding([KeyCode.shift], debugLabel: 'shift');

  /// A keybinding that registers as a combination of
  /// the `ctrl` and `alt` keys.
  static const ctrlAlt =
      Keybinding([KeyCode.ctrl, KeyCode.alt], debugLabel: 'ctrl-alt');

  /// A keybinding that registers as a combination of
  /// the `crtl` and `shift` keys.
  static const ctrlShift =
      Keybinding([KeyCode.ctrl, KeyCode.shift], debugLabel: 'ctrl-shift');

  /// A keybinding that registers as a combination of
  /// the `ctrl`, `alt`, and `shift` keys.
  static const ctrlAltShift = Keybinding(
      [KeyCode.ctrl, KeyCode.alt, KeyCode.shift],
      debugLabel: 'ctrl-alt-shift');

  /// A keybinding that registers as a combination of
  /// the `alt` and `shift` keys.
  static const shiftAlt =
      Keybinding([KeyCode.shift, KeyCode.alt], debugLabel: 'shift-alt');

  /// Returns a new [Keybinding] by merging `this` with the [KeyCode]s
  /// provided by [other].
  ///
  /// [other] must be a [Keybinding], [KeyCode], or [Iterable] of [KeyCode]s.
  Keybinding operator +(Object other) {
    assert(
        other is Keybinding || other is KeyCode || other is Iterable<KeyCode>);

    Keybinding keybinding;

    if (other is Keybinding) {
      keybinding = Keybinding(keyCodes.toList() + other.keyCodes.toList());
    } else if (other is KeyCode) {
      keybinding = Keybinding(keyCodes.toList()..add(other));
    } else if (other is Iterable<KeyCode>) {
      keybinding = Keybinding(keyCodes.toList() + other.toList());
    }

    return keybinding;
  }

  /// Returns `true` if `this` and [other] have equivalent [KeyCode]s.
  ///
  /// __Note:__ [KeyCode]s are considered equivalent to one another
  /// if any one of their [keyId]s are the same.
  bool equals(Keybinding other) {
    if (other == null || keyCodes.length != other.keyCodes.length) {
      return false;
    }

    final otherKeyCodes = List<KeyCode>.from(other.keyCodes);

    for (var keyCode in keyCodes) {
      if (!otherKeyCodes
          .removeFirstWhere((otherKeyCode) => keyCode.equals(otherKeyCode))) {
        return false;
      }
    }

    return true;
  }

  @override
  bool operator ==(Object other) =>
      other is Keybinding &&
      inclusive == other.inclusive &&
      keyCodes.matches(other.keyCodes);

  @override
  int get hashCode =>
      inclusive.hashCode ^
      (keyCodes.isEmpty
              ? null.hashCode
              : keyCodes
                  .map<int>((keyCode) => keyCode.hashCode)
                  .reduce((a, b) => a + b))
          .hashCode;

  @override
  String toString() => 'Keybinding(${debugLabel ?? keyCodes})';
}

/// {@template keybinder.KeyCode}
///
/// A set of [keyIds] representing a single abstract key.
///
/// When included as part of a [Keybinding], this [KeyCode] is acknowledged
/// as pressed when any one of the [keyIds] is pressed.
///
/// {@endtemplate}
class KeyCode {
  /// {@macro keybinder.KeyCode}
  ///
  /// [keyIds] must not be `null`.
  ///
  /// [label] is optional and exists for the sake of external convenience.
  const KeyCode(this.keyIds, {this.label}) : assert(keyIds != null);

  /// Creates a [KeyCode] from a [LogicalKeyboardKey].
  factory KeyCode.from(KeyboardKey key, {String label}) {
    assert(key != null);
    return KeyCode({_getKeyId(key)}, label: label ?? _getKeyLabel(key));
  }

  /// Creates a [KeyCode] from a set of [LogicalKeyboardKey]s.
  factory KeyCode.fromSet(Iterable<KeyboardKey> keys, {String label}) {
    assert(keys != null);
    return KeyCode(keys.map<int>((key) => _getKeyId(key)).toSet(),
        label: label);
  }

  /// The key ID(s) representing this [KeyCode].
  final Set<int> keyIds;

  /// The optional label of the key(s) represented by this [KeyCode].
  final String label;

  /// A [KeyCode] representing both `alt` keys.
  static const alt = KeyCode({0x001000700e2, 0x001000700e6}, label: 'alt');

  /// A [KeyCode] representing both `ctrl` keys.
  static const ctrl = KeyCode({0x001000700e0, 0x001000700e4}, label: 'ctrl');

  /// A [KeyCode] representing both `shift` keys.
  static const shift = KeyCode({0x001000700e1, 0x001000700e5}, label: 'shift');

  /// Returns `true` if this and [other] have any of the same [keyId]s.
  bool equals(KeyCode other) => keyIds.any((key) => other.keyIds.contains(key));

  @override
  bool operator ==(Object other) =>
      other is KeyCode && keyIds.matches(other.keyIds);

  @override
  int get hashCode => keyIds.reduce((a, b) => a.hashCode + b.hashCode).hashCode;

  @override
  String toString() => 'KeyCode(${label ?? keyIds})';

  /// Returns the [int] representing the keyboard key from [key].
  static int _getKeyId(KeyboardKey key) => key is LogicalKeyboardKey
      ? key.keyId
      : (key as PhysicalKeyboardKey).usbHidUsage;

  /// Returns the label representing [key].
  static String _getKeyLabel(KeyboardKey key) => key is LogicalKeyboardKey
      ? key.keyLabel ?? key.debugName
      : (key as PhysicalKeyboardKey).debugName;
}
