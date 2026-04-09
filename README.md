# PokeBar

![Version](https://img.shields.io/badge/version-v2-blue)
![Languages](https://img.shields.io/badge/languages-EN%20%7C%20JP-success)

<div align="center">
  <h3>Pokémon-themed macOS menu bar system monitor</h3>
  <p>Sleeping Pokémon in the menu bar; CPU, RAM, and Network stats in the popover.</p>
  <img src="demo/demo.gif" alt="PokeBar demo" />
</div>

Japanese README: [README.ja.md](README.ja.md)

**Homebrew:**

```bash
brew install --cask keshav-k3/tap/pokebar
```

**Direct download:** [latest release](https://github.com/keshav-k3/PokeBar/releases/latest)

**Currently supported Pokemon:** Pikachu, Charmander, Squirtle, Bulbasaur, Jigglypuff, Psyduck, Eevee, Oshawott, Dragonite, Snorlax

<div align="center">
  <h3>Choose your Pokemon</h3>
  <table>
    <tr>
      <td valign="top"><img src="demo/demo-monitor-en.png" width="560" alt="Choose your Pokémon — menu bar monitor (English)" /></td>
    </tr>
  </table>
</div>

**macOS “damaged” or won’t open:** PokeBar is not Apple-notarized. After install, clear quarantine once:

```bash
xattr -dr com.apple.quarantine /Applications/PokeBar.app
```

You can also try **right-click → Open** on `PokeBar.app` the first time.
