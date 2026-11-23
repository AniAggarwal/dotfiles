import QtQuick

// A BarButton in the theme's colors, for use inside dropdowns.
BarButton {
    required property BarState theme
    foreground: theme.foreground
    accent: theme.accent
}
