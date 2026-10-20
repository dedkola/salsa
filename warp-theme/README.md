# Apple Glass for Warp

A light, Apple-inspired Warp theme based on the attached prototype: a focused blue
accent, a pearl-white terminal surface, graphite text, and restrained
status colors that stay readable in long sessions.

## Install on macOS

Warp discovers custom themes from `~/.warp/themes/`.

```sh
mkdir -p ~/.warp/themes
cp apple-glass.yaml ~/.warp/themes/
```

Restart Warp if this is the first custom theme added. Then open **Settings →
Appearance → Themes** and choose **Apple Glass**.

## Palette decisions

- A single blue accent gives focus and selection states a consistent identity.
- The background moves almost imperceptibly from white to neutral pearl,
  keeping the terminal close to the prototype's clean content panel.
- Graphite text and neutral grays establish a clear visual hierarchy. ANSI white
  slots use dark neutrals so text remains visible on this light surface.
- Forest green, warm amber, coral red, orchid, and teal are tuned for light-mode
  readability. Bright variants add a modest lift without becoming neon.

The YAML controls the palette. It cannot recreate the prototype's custom sidebar,
rounded cards, or window layout. Transparency, blur, and fonts are separate Warp
settings; the background gradient itself does not create a glass effect.

Warp's custom theme format is documented at:
https://docs.warp.dev/terminal/appearance/custom-themes/
