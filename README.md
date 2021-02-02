# keybinder

A utility class used to bind callbacks to a combination of one or more
physical keys on a keyboard; utilizing the global
[[RawKeyboard](https://api.flutter.dev/flutter/services/RawKeyboard-class.html)]
instance.

# Usage

```dart
import 'package:keybinder/keybinder.dart';
```

## KeyCodes

Keys in keybinder are represented by [KeyCode]s, which consist
of a set of one or more key IDs, which correspond to physical
or logical keyboard keys.

A [KeyCode] is treated as a single abstract key, in that if any
of the keys in the set of key IDs representing it are pressed,
the [KeyCode] is considered pressed.

[KeyCode]s can be constructed directly from a set of key IDs, or
can be constructed from one or more
[[LogicalKeyboardKey](https://api.flutter.dev/flutter/services/LogicalKeyboardKey-class.html)]s
and/or [[PhysicalKeyboardKey](https://api.flutter.dev/flutter/services/PhysicalKeyboardKey-class.html)]s.

```dart
/// This [KeyCode]s key IDs represent the logical left and right
/// control keys, and is considered pressed when either of those
/// keys are pressed.
final ctrlA = KeyCode({0x001000700e0, 0x001000700e4});

/// This [KeyCode] is the same as the one above, but constructed
/// from [LogicalKeyboardKey]'s constants.
final ctrlB = KeyCode.fromSet({LogicalKeyboardKey.ctrlLeft, LogicalKeyboardKey.ctrlRight});

/// This [KeyCode] is considered pressed when the left control key
/// is pressed, but not the right control key.
final ctrlLeft = KeyCode.from(LogicalKeyboardKey.ctrlLeft);
```

[KeyCode] has constants for the `alt`, `ctrl`, and `shift` keys,
represented by their respective left and right logical keys, like
the first two examples above.

```dart
/// This [KeyCode] is considered pressed if either `alt` key is pressed.
final alt = KeyCode.alt;

/// This [KeyCode] is considered pressed if either `ctrl` key is pressed.
final ctrl = KeyCode.ctrl;

/// This [KeyCode] is considered pressed if either `shift` key is pressed.
final shift = KeyCode.shift;
```

## Keybindings

[Keybinding]s consist of a set of [KeyCode]s and are used to bind
callbacks to a combination of zero or more keys on a keyboard.

By default, [Keybinding]s are exclusive, meaning they're only treated
as pressed if all of their [KeyCode]s are pressed, and no additional
keys have been pressed. If [inclusive] is set to `true`, the [Keybinding]
will be treated as pressed as long as all of its [KeyCode]s are pressed,
regardless of whether any additional keys are pressed.

```dart
/// This [Keybinding] is considered pressed if both the control and shift keys
/// are pressed, but no additional keys are pressed.
final exclusive = Keybinding({KeyCode.ctrl, KeyCode.shift});

/// This [Keybinding] is considered pressed if both the control and shift keys
/// are pressed, regardless of whether any additional keys are pressed.
final inclusive = Keybinding({KeyCode.ctrl, KeyCode.shift}, inclusive: true);
```

__Note:__ [Keybinding] has constants for the `alt`, `ctrl`, and `shift` keys,
and the combinations thereof.
__See:__ [Keybinding](https://pub.dev/documentation/keybinder/latest/keybinder/Keybinding-class.html#constants)

### Empty Keybindings

[Keybinding]s may be empty, in which case they will be considered
pressed when no other keys are pressed, regardless of whether the
[Keybinding] is [inclusive] or not.

```dart
/// Empty [Keybinding]s can be created with the [empty] constructor, or
/// by constructing a [Keybinding] with an empty [Set]: `Keybinding({})`.
final empty = Keybinding.empty();
```

### isPressed

A [Keybinding]'s [isPressed] getter can be called at any time to check
whether the keys representing it are currently pressed on the keyboard.

```dart
/// Prints `true` if either `ctrl` key is currently pressed on
/// the keyboard, otherwise prints `false`.
print(Keybinding.ctrl.isPressed);
```

## Keybinder

[Keybinder] is the utility class that handles binding [Keybinding]s to their
respective callbacks, and calling those callbacks when their [Keybinding]
has been pressed or released.

### Callbacks

[Keybinding]s can be bound to one of three types of callbacks:

A function without parameters, which will only be called when the
[Keybinding] is pressed, but not when it's released.

```dart
/// When the `space` key is pressed, this callback will
/// print `Keybinding was pressed`.
void onPressed() {
  print('Keybinding was pressed');
}
```

A `ValueChanged<bool>` callback (a function with a single boolean parameter,)
which will be called with `true` when the [Keybinding] is pressed, or `false`
when it's been released.

```dart
/// When the `space` key is pressed or released, this callback will print
/// `Keybinding was pressed` or `Keybinding was released`.
void onToggle(bool pressed) {
  print('Keybinding was ${pressed ? 'pressed' : 'released'}');
}
```

Or, a [KeybindingEvent], which is provided the relevant [Keybinding] and
a boolean value representing whether the key was pressed or released, as
described by the previous callback.

```dart
/// When the key(s) bound to this callback are pressed/released, in this case,
/// the `space` key, this callback will print: `Keybinding(space) was pressed`
/// or `Keybinding(space) was released`.
void onKeyToggled(Keybinding keybinding, bool pressed) {
  print('$keybinding was ${pressed ? 'pressed' : 'released'}');
}
```

### Binding Keybindings

[Keybinding]s can be bound to a callback with [Keybinder]'s [register] method.

```dart
/// A keybinding associated with the `space` key.
final keybinding = Keybinding.from(
    {LogicalKeyboardKey.space}, debugLabel: 'space');

/// Binds all three callbacks above to the `space` key.
Keybinder.bind(keybinding, onPressed);
Keybinder.bind(keybinding, onToggle);
Keybinder.bind(keybinding, onKeyToggled);
```

### Removing Keybindings

[Keybinding]s and their associated callbacks can be removed by [Keybinder]'s
[remove] method.

```dart
/// Removes the [Keybinding] bound in the previous example from [Keybinder].
Keybinder.remove(keybinding, onPressed);
```

__Note:__ [Keybinder] has a [dispose] method which clears every
bound/registered [Keybinding] and their respective callbacks, and
removes [Keybinder]'s listener from the [RawKeyboard] instance.
[Keybinder] can continue to be used normally after [dispose] has
been called, a new listener will be added to the [RawKeyboard]
instance once another [Keybinding] has been registered.

```dart
/// Removes every [Keybinding], as well as the listener on
/// the global [RawKeyboard] instance.
Keybinder.dispose();
```
