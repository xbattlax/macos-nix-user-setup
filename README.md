# Provisionnement macOS : compte, Nix et applications

Ce script crée un compte utilisateur standard et installe, si nécessaire :

- Nix (installation officielle en mode multi-utilisateur)
- Homebrew
- Google Chrome
- Claude Desktop et Claude Code
- Microsoft Office pour Mac (applications locales)

Les applications sont installées pour le Mac via Homebrew. Nix est disponible pour les comptes de la machine, mais le script ne gère pas les applications avec nix-darwin.

## Prérequis

- macOS 14 ou plus récent pour le paquet Office. Homebrew prend officiellement en charge macOS 15 ou plus récent sur Apple Silicon ; macOS 14 peut fonctionner sans être pris en charge.
- Une session administrateur avec accès Internet et un terminal interactif.
- Une licence Microsoft adaptée pour activer Office et un compte Claude pour utiliser Claude.

## Utilisation

Depuis la session administrateur, sans lancer le script avec `sudo` :

```bash
chmod +x provision-macos-nix.sh
./provision-macos-nix.sh nom_utilisateur -
```

Le `-` fait demander le mot de passe du nouveau compte par macOS, sans l'inscrire dans la commande ni l'exposer dans ses arguments. L'authentification de l'administrateur est demandée pendant l'installation et la création du compte.

Le script accepte aussi `./provision-macos-nix.sh nom_utilisateur mot_de_passe`, mais ce format peut exposer le mot de passe dans l'historique du terminal et la liste des processus. Le compte ne doit pas déjà exister. Il est créé comme utilisateur standard. À la fin, le script affiche l'état de son Secure Token.

## Références

- [Installation officielle de Nix sur macOS](https://nixos.org/download/)
- [Installation de Homebrew](https://docs.brew.sh/Installation)
- [Paquet Homebrew Microsoft Office](https://formulae.brew.sh/cask/microsoft-office)
- [Secure Token sur macOS](https://support.apple.com/guide/deployment/use-secure-token-bootstrap-token-and-volume-ownership-dep24dbdcf9e/web)
