#!/bin/bash

set -euo pipefail
set +x

usage() {
  cat <<'EOF'
Usage: ./provision-macos-nix.sh NOM_UTILISATEUR MOT_DE_PASSE
       ./provision-macos-nix.sh NOM_UTILISATEUR -
       ./provision-macos-nix.sh --apps-only

Le second format demande le mot de passe sans l'afficher ni le placer
dans l'historique du shell. Le script doit être lancé depuis une session
administrateur macOS, sans sudo.
EOF
}

die() { printf 'Erreur : %s\n' "$*" >&2; exit 1; }

apps_only=0
if [[ $# -eq 1 && $1 == --apps-only ]]; then
  apps_only=1
  username=''
  user_password=''
else
  [[ $# -eq 2 ]] || { usage >&2; exit 2; }
  username=$1
  user_password=$2
fi

[[ $(uname -s) == Darwin ]] || die 'Ce script est réservé à macOS.'
[[ $EUID -ne 0 ]] || die 'Lancez ce script depuis la session admin, sans sudo.'
if [[ $apps_only -eq 0 ]]; then
  [[ $username =~ ^[a-z_][a-z0-9_-]{0,30}$ ]] || die 'Nom court invalide (lettres minuscules, chiffres, _ ou -).'
fi
id -Gn | /usr/bin/grep -Eq '(^| )admin( |$)' || die 'La session courante doit être administrateur.'

macos_major=$(/usr/bin/sw_vers -productVersion | /usr/bin/cut -d. -f1)
[[ $macos_major =~ ^[0-9]+$ && $macos_major -ge 14 ]] || die 'Microsoft Office via Homebrew nécessite macOS 14 ou plus récent.'

[[ -t 0 ]] || die "Un terminal interactif est requis pour l'authentification admin."
if [[ $apps_only -eq 0 ]]; then
  [[ -n $user_password ]] || die 'Le mot de passe ne peut pas être vide.'
  /usr/bin/dscl . -read "/Users/$username" >/dev/null 2>&1 && die "Le compte $username existe déjà."
fi

# sudo demande le mot de passe de la session administrateur déjà ouverte,
# pas celui du nouveau compte.
printf 'Authentification de la session administrateur en cours…\n'
/usr/bin/sudo -p '[sudo] Mot de passe de la session administrateur : ' -v

if [[ $apps_only -eq 1 || ${JEF_INSTALL_NIX:-0} != 1 ]]; then
  printf 'Installation de Nix reportée (pour l’activer : JEF_INSTALL_NIX=1).\n'
elif ! command -v nix >/dev/null 2>&1 \
  && [[ ! -x /nix/var/nix/profiles/default/bin/nix ]]; then
  printf 'Installation de Nix (mode multi-utilisateur)…\n'
  /usr/bin/curl --proto '=https' --tlsv1.2 -fsSL https://nixos.org/nix/install | /bin/sh
  [[ -x /nix/var/nix/profiles/default/bin/nix ]] || die "Nix n'est pas disponible après son installation."
fi

failed_apps=()
if ! command -v brew >/dev/null 2>&1 \
  && [[ ! -x /opt/homebrew/bin/brew ]] \
  && [[ ! -x /usr/local/bin/brew ]]; then
  printf 'Installation de Homebrew…\n'
  if installer=$(/usr/bin/curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh); then
    if ! /bin/bash -c "$installer"; then
      printf 'Attention : installation de Homebrew échouée ; les applications seront à reprendre.\n' >&2
    fi
  else
    printf 'Attention : téléchargement de Homebrew échoué ; les applications seront à reprendre.\n' >&2
  fi
fi

if [[ -x /opt/homebrew/bin/brew ]]; then
  brew_cmd=/opt/homebrew/bin/brew
elif [[ -x /usr/local/bin/brew ]]; then
  brew_cmd=/usr/local/bin/brew
else
  brew_cmd=''
  printf 'Attention : Homebrew est introuvable ; installation des applications reportée.\n' >&2
fi

if [[ -n $brew_cmd ]]; then
  # path_helper lit /etc/paths.d à l'ouverture d'une nouvelle session :
  # Claude Code sera ainsi disponible pour le compte créé sur Apple Silicon.
  if brew_prefix=$("$brew_cmd" --prefix); then
    brew_bin="$brew_prefix/bin"
    if [[ ! -f /etc/paths.d/homebrew ]] || ! /usr/bin/grep -Fxq "$brew_bin" /etc/paths.d/homebrew; then
      printf '%s\n' "$brew_bin" | /usr/bin/sudo /usr/bin/tee -a /etc/paths.d/homebrew >/dev/null
    fi
  else
    printf 'Attention : préfixe Homebrew indisponible ; chemin Claude Code à vérifier.\n' >&2
  fi

  for cask in google-chrome claude claude-code microsoft-office adobe-creative-cloud displaylink webex chatgpt codex codex-app; do
    if "$brew_cmd" list --cask "$cask" >/dev/null 2>&1; then
      printf 'Déjà installé : %s\n' "$cask"
    else
      printf 'Installation : %s\n' "$cask"
      if ! "$brew_cmd" install --cask "$cask"; then
        failed_apps+=("$cask")
        printf 'Attention : installation de %s échouée ; poursuite du script.\n' "$cask" >&2
      fi
    fi
  done
fi

report_apps() {
  if [[ -z $brew_cmd ]]; then
    printf 'Applications à reprendre : Homebrew et toutes les applications.\n'
  elif ((${#failed_apps[@]})); then
    printf 'Applications à reprendre : %s\n' "${failed_apps[*]}"
  else
    printf 'Toutes les applications demandées sont installées ou déjà présentes.\n'
  fi
}

if [[ $apps_only -eq 1 ]]; then
  printf '\n'
  report_apps
  printf 'Nix et les comptes utilisateurs n’ont pas été modifiés.\n'
  exit 0
fi

printf 'Création du compte standard %s…\n' "$username"
printf "macOS demandera le mot de passe du nouveau compte, puis pourra redemander celui de l'administrateur.\n"
# Avec -password -, sysadminctl demande lui-même le mot de passe sans
# l'exposer dans les arguments du processus. interactive permet à macOS
# de demander les identifiants de l'admin pour le Secure Token.
/usr/bin/sudo /usr/sbin/sysadminctl interactive -addUser "$username" \
  -fullName "$username" \
  -home "/Users/$username" \
  -password "$user_password"

unset user_password
/usr/bin/dscl . -read "/Users/$username" >/dev/null 2>&1 || die "Le compte n'a pas été créé."
/usr/bin/sudo /usr/sbin/sysadminctl -secureTokenStatus "$username"

printf '\nTerminé : compte %s créé.\n' "$username"
report_apps
printf 'À la première ouverture, connectez Claude, Adobe et Webex et activez Office avec une licence Microsoft valide.\n'
printf 'Pour les écrans DisplayLink, redémarrez le Mac, ouvrez DisplayLink Manager, activez son lancement à la connexion et autorisez Enregistrement de l’écran dans Réglages système.\n'
