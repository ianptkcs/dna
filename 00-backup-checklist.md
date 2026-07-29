# Backup checklist (fazer ANTES de formatar)

Marque conforme for salvando. Destino sugerido: um HD externo **e** nuvem
(Drive/GitHub) — segredos NÃO vão pro GitHub público.

## 🔴 Segredos / credenciais (perda = dor de cabeça séria)

- [ ] `~/.ssh/` (chaves SSH) — 20K
- [ ] `~/.gnupg/` (chaves GPG) — 204K
- [ ] `~/.config/gcloud/` (auth gcloud/gsutil/bq)
- [ ] `~/.config/gh/` (token GitHub CLI)
- [ ] `~/.sfdx/` e `~/.sf/` (Salesforce CLI)
- [ ] `~/.turso/` + `~/.config/turso/`
- [ ] `~/.npmrc`, `~/.config/configstore/` (tokens npm/firebase)
- [ ] `~/.aws/` se existir; `~/.netrc` se existir
- [ ] `~/.claude/` + `~/.claude.json` (config + auth do Claude Code)
- [ ] `~/.copilot/` + `~/.config/github-copilot/`
- [ ] sigstore/cosign: `~/.sigstore/`, `~/sops-v3.13.0.*`
- [ ] **Senhas do navegador**: exportar do Brave/Firefox OU confiar na sync da conta

> Dica: `tar czf segredos.tgz ~/.ssh ~/.gnupg ~/.config/gcloud ~/.config/gh ~/.sfdx ~/.sf ~/.turso ~/.config/turso ~/.npmrc ~/.config/configstore ~/.claude ~/.claude.json ~/.copilot ~/.config/github-copilot`
> e guardar esse `.tgz` cifrado (ex.: `gpg -c segredos.tgz`).

## 🟡 Dados / projetos (na home)

- [ ] `~/dotfiles/` → **`git push` primeiro!** (verificar `git status`/branch)
- [ ] `~/codigo/` (projetos)
- [ ] `~/mandarim/`
- [ ] `~/rpg/`
- [ ] `~/Android/`, `~/.android/` (AVDs/SDK — pesado, opcional)
- [ ] `~/go/` (workspace Go — reproduzível, opcional)
- [ ] `~/ecovita-gpt-evidence-2026-05-29/`
- [ ] `~/brave-bookmarks-export`, `~/fazendo.md`, `~/out.ogv`
- [ ] `~/Documents`, `~/Downloads`, `~/Pictures`, `~/Videos`, `~/Music`, `~/Desktop`
- [ ] **Flatpak app data** `~/.var/app/` — **17 GB** (estado de Anki, Android Studio,
      Spotify, etc.). Backup seletivo: Anki (`~/.var/app/net.ankiweb.Anki`) é o que
      mais dói perder; o resto recria. Use a sync do Anki também.

## 🟢 Configs fora do dotfiles (recriáveis, mas vale anotar)

Estes diretórios em `~/.config` **não** estão no stow e podem ter ajuste manual:
- [ ] `OpenRGB/` (perfis de RGB)
- [ ] `cava/` (visualizador de áudio)
- [ ] `ibus/` (input method — config do mandarim/cangjie)
- [ ] `qt5ct/`, `qt6ct/` (tema Qt)
- [ ] `tiling-assistant/`, `monitors.xml` (layout de telas)
- [ ] `mimeapps.list` (apps padrão por tipo de arquivo)
- [ ] `git` (já tem em dotfiles? confirmar `~/.gitconfig` vs `~/dotfiles/git`)

> Já versionado via stow (só dar `git push`): alacritty, DankMaterialShell,
> fish, foot, mise, niri, nvim, starship, yazi, tmux.

## Pós-backup: validar

- [ ] `~/dotfiles` está no GitHub e atualizado (incluindo `foot/` e `y.fish` novos)
- [ ] consigo abrir o `.tgz` de segredos cifrado
- [ ] tenho a lista de pacotes (`raw/apt-manual.txt`) e este diretório no repo
