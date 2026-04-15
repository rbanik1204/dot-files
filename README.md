<div align="center">

```
██╗  ██╗██╗   ██╗██████╗ ██████╗ ██╗      █████╗ ███╗   ██╗██████╗
██║  ██║╚██╗ ██╔╝██╔══██╗██╔══██╗██║     ██╔══██╗████╗  ██║██╔══██╗
███████║ ╚████╔╝ ██████╔╝██████╔╝██║     ███████║██╔██╗ ██║██║  ██║
██╔══██║  ╚██╔╝  ██╔═══╝ ██╔══██╗██║     ██╔══██║██║╚██╗██║██║  ██║
██║  ██║   ██║   ██║     ██║  ██║███████╗██║  ██║██║ ╚████║██████╔╝
╚═╝  ╚═╝   ╚═╝   ╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═════╝
```

**A desktop environment that doesn't compromise. Ever.**
**Microslop && NVIDIA F*k u**

<br>

[![Hyprland](https://img.shields.io/badge/Hyprland-0.45-blue?style=flat-square&logo=linux&logoColor=white)](https://hyprland.org)
[![Arch Linux](https://img.shields.io/badge/Arch_Linux-1793D1?style=flat-square&logo=arch-linux&logoColor=white)](https://archlinux.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](LICENSE)
[![Stars](https://img.shields.io/github/stars/rbanik1204/dotfiles?style=flat-square&color=yellow)](https://github.com/rbanik1204)
[![Last Commit](https://img.shields.io/github/last-commit/rbanik1204/dotfiles?style=flat-square)](https://github.com/rbanik1204)

<br>

> *"Most people configure a desktop. This is a philosophy."*

<br>

![Preview](https://github.com/user-attachments/assets/df88cc99-63cb-4552-89e1-043475183426)

</div>

---

<br>

## ◈ What This Is

This is not a theme pack. Not a collection of colorschemes slapped together after watching a YouTube tutorial. This is a **handcrafted desktop environment** built from the ground up — every pixel intentional, every keybind considered, every module earns its place on the bar.

Built around **Hyprland's** Wayland compositor and powered by **Matugen's** dynamic color pipeline, this setup adapts to *you* — your wallpaper dictates your palette, and that palette flows into every corner of the system.

<br>

---

## ◈ The Stack

| Layer | Tool | Role |
|-------|------|------|
| 🧱 **Compositor** | Hyprland | Wayland WM with buttery animations |
| 📊 **Status Bar** | Waybar | Network speed, media, time, system |
| 🐱 **Terminal** | Kitty | GPU-accelerated, custom-colored |
| 🔍 **Launcher** | Rofi + Wofi | Dual launchers, unified theme |
| 🎨 **Theming** | Matugen | Material You dynamic color engine |
| 🔊 **Audio** | PulseAudio + Pavucontrol | Full audio stack |
| 📁 **Files** | Thunar | Lightweight GTK file manager |

<br>

---

## ◈ Features That Actually Matter

### ⚡ Performance First
No electron. No heavy DEs. No wasted RAM. Hyprland uses GPU acceleration for compositing, meaning you get fluid 60fps (or higher) animations with virtually zero CPU overhead.

### 🎨 Dynamic Theming via Matugen
Swap your wallpaper → every single app recolors itself automatically. Waybar, Kitty, Rofi, Wofi — all pulling from the same generated palette. Zero manual color editing. Ever.

### 📊 A Waybar That Does More
- **Real-time network speed** (upload + download, in your bar)
- **Media integration** — see what's playing without leaving the keyboard
- **Clickable modules** — everything is interactive, nothing is decorative
- **Unified colors** — matches your wallpaper like it was designed that way

### 🐱 Kitty Terminal
Not just a terminal. A GPU-accelerated powerhouse with color schemes that snap to your Matugen palette automatically.

### 🔍 Rofi + Wofi
Two launchers because different workflows deserve different tools. Both themed consistently. Both blazing fast.

<br>

---

## ◈ Directory Layout

```
dotfiles/
│
├── 📂 hypr/                    # The brain
│   ├── hyprland.conf           # Core config — keybinds, layouts, rules
│   ├── env.conf                # Environment variables
│   └── keybinds.conf           # Keybind definitions
│
├── 📂 waybar/                  # The face
│   ├── config                  # Module layout & logic
│   └── style.css               # Matugen-powered styling
│
├── 📂 kitty/                   # The terminal
│   └── colors/                 # Dynamic color schemes
│
├── 📂 rofi/                    # The launcher (X11-compatible)
│   └── colors/                 # Themed to match palette
│
├── 📂 matugen/                 # The color engine
│   └── config.toml             # Generation rules
│
├── 📂 pulse/                   # Audio stack
├── 📂 Thunar/                  # File manager
├── 📂 dconf/                   # GNOME compatibility layer
├── mimeapps.list               # Default app associations
└── pavucontrol.ini             # Audio control UI config
```

<br>

---

## ◈ Installation

> ⚠️ **Read this fully before touching your system.**

<br>

### Step 1 — Clone

```bash
git clone https://github.com/rbanik1204/<repo-name>.git
cd <repo-name>
```

<br>

### Step 2 — Back Everything Up

```bash
# Don't skip this. Seriously.
mkdir -p ~/.config/backups

for dir in hypr waybar kitty rofi wofi matugen; do
  [ -d ~/.config/$dir ] && cp -r ~/.config/$dir ~/.config/backups/${dir}_backup
done

echo "✓ Backups saved to ~/.config/backups/"
```

<br>

### Step 3 — Install Dependencies

**Arch Linux (pacman):**
```bash
sudo pacman -S --needed \
  hyprland \
  waybar \
  kitty \
  rofi \
  wofi \
  playerctl \
  pavucontrol \
  networkmanager \
  polkit-gnome \
  xdg-desktop-portal-hyprland
```

**AUR (via yay or paru):**
```bash
yay -S matugen-bin
# or
paru -S matugen-bin
```

<br>

### Step 4 — Deploy Configs

```bash
cp -r hypr waybar kitty rofi wofi matugen pulse Thunar ~/.config/
cp mimeapps.list ~/.config/
cp pavucontrol.ini ~/.config/
```

<br>

### Step 5 — Generate Your Theme

```bash
# Point matugen at your wallpaper
matugen image /path/to/your/wallpaper.jpg
```

This single command regenerates color schemes across **all configured applications** simultaneously.

<br>

### Step 6 — Launch

```bash
# Log out of your current session and select Hyprland from your display manager
# Or start directly:
Hyprland
```

<br>

---

## ◈ Customization Guide

### Keybindings → `hypr/hyprland.conf`

```bash
# Example: Change terminal keybind
bind = $mainMod, Return, exec, kitty

# Example: Custom app launcher
bind = $mainMod, Space, exec, rofi -show drun
```

### Waybar Modules → `waybar/config`
Add, remove, or reorder modules in the `"modules-left"`, `"modules-center"`, and `"modules-right"` arrays.

### Colors → `matugen/config.toml`
Change the source wallpaper path and re-run `matugen image` to regenerate everything.

### Bar Style → `waybar/style.css`
All Waybar styling is Matugen-aware. Edit CSS variables at the top of the file.

<br>

---

## ◈ Troubleshooting

<details>
<summary><b>Waybar won't start / shows errors</b></summary>

Run `waybar` in a terminal to see the error output directly. Most issues are missing modules or misconfigured `exec` paths.

```bash
waybar --log-level debug
```

</details>

<details>
<summary><b>Matugen not generating colors</b></summary>

Ensure the wallpaper path is absolute, not relative:

```bash
matugen image /home/yourusername/Pictures/wallpaper.jpg
```

</details>

<details>
<summary><b>Rofi theme doesn't match</b></summary>

Re-run matugen after installation — the Rofi colors are generated dynamically and won't exist until matugen runs at least once.

</details>

<details>
<summary><b>Screen sharing / OBS doesn't work</b></summary>

Install `xdg-desktop-portal-hyprland` and make sure it's running:

```bash
systemctl --user enable --now xdg-desktop-portal-hyprland
```

</details>

<details>
<summary><b>GTK apps look inconsistent</b></summary>

Apply the dconf settings:

```bash
dconf load / < dconf/settings.dconf
```

</details>

<br>

---

## ◈ Requirements

- **OS:** Arch Linux (or Arch-based: EndeavourOS, CachyOS, Garuda)
- **GPU:** Any GPU with Wayland + EGL support (AMD recommended)
- **Display Server:** Wayland (X11 is not supported)
- **Fonts:** A Nerd Font patched font is required for Waybar icons

> **Recommended font:** `ttf-jetbrains-mono-nerd` from the AUR

<br>

---

## ◈ Contributing

Spotted something broken? Have an improvement that genuinely makes it better?

1. Fork the repo
2. Create a feature branch (`git checkout -b feature/your-feature`)
3. Commit with a clear message (`git commit -m 'feat: add X because Y'`)
4. Open a Pull Request — describe *why*, not just *what*

All contributions welcome. Bikeshedding is not.

<br>

---

## ◈ License

MIT — take it, modify it, ship it. Credit appreciated, not required.

<br>

---

<div align="center">

## ◈ Author

**Ratul Banik**

[![GitHub](https://img.shields.io/badge/GitHub-rbanik1204-181717?style=flat-square&logo=github)](https://github.com/rbanik1204)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-ratul--banik1204-0A66C2?style=flat-square&logo=linkedin)](https://www.linkedin.com/in/ratul-banik1204/)

<br>

---

*If this setup made your desktop better, a ⭐ goes a long way.*

*If it made your desktop significantly better, tell someone.*

<br>

```
built different. runs different. looks different.
```

</div>
