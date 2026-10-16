#!/bin/bash

set -euo pipefail
set +x

usage() {
  cat <<'EOF'
Usage: ./provision-macos-nix.sh NOM_UTILISATEUR MOT_DE_PASSE
       ./provision-macos-nix.sh NOM_UTILISATEUR -

Le second format demande le mot de passe sans l'afficher ni le placer
dans l'historique du shell. Le script doit être lancé depuis une session
administrateur macOS, sans sudo.
EOF
}

die() { printf 'Erreur : %s\n' "$*" >&2; exit 1; }

[[ $# -eq 2 ]] || { usage >&2; exit 2; }
username=$1
user_password=$2

[[ $(uname -s) == Darwin ]] || die 'Ce script est réservé à macOS.'
[[ $EUID -ne 0 ]] || die 'Lancez ce script depuis la session admin, sans sudo.'
[[ $username =~ ^[a-z_][a-z0-9_-]{0,30}$ ]] || die 'Nom court invalide (lettres minuscules, chiffres, _ ou -).'
id -Gn | /usr/bin/grep -Eq '(^| )admin( |$)' || die 'La session courante doit être administrateur.'

macos_major=$(/usr/bin/sw_vers -productVersion | /usr/bin/cut -d. -f1)
[[ $macos_major =~ ^[0-9]+$ && $macos_major -ge 14 ]] || die 'Microsoft Office via Homebrew nécessite macOS 14 ou plus récent.'

[[ -t 0 ]] || die "Un terminal interactif est requis pour l'authentification admin."
[[ -n $user_password ]] || die 'Le mot de passe ne peut pas être vide.'

/usr/bin/dscl . -read "/Users/$username" >/dev/null 2>&1 && die "Le compte $username existe déjà."

# sudo demande le mot de passe de la session administrateur déjà ouverte,
# pas celui du nouveau compte.
printf 'Authentification de la session administrateur en cours…\n'
/usr/bin/sudo -p '[sudo] Mot de passe de la session administrateur : ' -v

if ! command -v nix >/dev/null 2>&1 \
  && [[ ! -x /nix/var/nix/profiles/default/bin/nix ]]; then
  printf 'Installation de Nix (mode multi-utilisateur)…\n'
  /usr/bin/curl --proto '=https' --tlsv1.2 -fsSL https://nixos.org/nix/install | /bin/sh
  [[ -x /nix/var/nix/profiles/default/bin/nix ]] || die "Nix n'est pas disponible après son installation."
fi

if ! command -v brew >/dev/null 2>&1 \
  && [[ ! -x /opt/homebrew/bin/brew ]] \
  && [[ ! -x /usr/local/bin/brew ]]; then
  printf 'Installation de Homebrew…\n'
  /bin/bash -c "$(/usr/bin/curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

if [[ -x /opt/homebrew/bin/brew ]]; then
  brew_cmd=/opt/homebrew/bin/brew
elif [[ -x /usr/local/bin/brew ]]; then
  brew_cmd=/usr/local/bin/brew
else
  die 'Homebrew est introuvable après son installation.'
fi

# path_helper lit /etc/paths.d à l'ouverture d'une nouvelle session :
# Claude Code sera ainsi disponible pour le compte créé sur Apple Silicon.
brew_bin="$("$brew_cmd" --prefix)/bin"
if [[ ! -f /etc/paths.d/homebrew ]] || ! /usr/bin/grep -Fxq "$brew_bin" /etc/paths.d/homebrew; then
  printf '%s\n' "$brew_bin" | /usr/bin/sudo /usr/bin/tee -a /etc/paths.d/homebrew >/dev/null
fi

for cask in google-chrome claude claude-code microsoft-office; do
  if "$brew_cmd" list --cask "$cask" >/dev/null 2>&1; then
    printf 'Déjà installé : %s\n' "$cask"
  else
    printf 'Installation : %s\n' "$cask"
    "$brew_cmd" install --cask "$cask"
  fi
done

printf 'Création du compte standard %s…\n' "$username"
printf "macOS demandera le mot de passe du nouveau compte, puis pourra redemander celui de l'administrateur.\n"
# Avec -password -, sysadminctl demande lui-même le mot de passe sans
# l'exposer dans les arguments du processus. interactive permet à macOS
# de demander les identifiants de l'admin pour le Secure Token.
/usr/bin/sudo /usr/sbin/sysadminctl -addUser "$username" \
  -fullName "$username" \
  -home "/Users/$username" \
  -password "$user_password" \
  interactive

unset user_password
/usr/bin/dscl . -read "/Users/$username" >/dev/null 2>&1 || die "Le compte n'a pas été créé."
/usr/bin/sudo /usr/sbin/sysadminctl -secureTokenStatus "$username"

printf '\nTerminé : compte %s créé. Chrome, Claude Desktop, Claude Code et Office sont installés.\n' "$username"
printf 'À la première ouverture, connectez Claude et activez Office avec une licence Microsoft valide.\n'
