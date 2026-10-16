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

Depuis une session administrateur macOS, remplacez `nom_utilisateur` par le nom court du nouveau compte, puis exécutez cette commande dans le Terminal, **sans `sudo`** :

```bash
curl -fsSL https://raw.githubusercontent.com/xbattlax/macos-nix-user-setup/main/provision-macos-nix.sh -o provision-macos-nix.sh && bash provision-macos-nix.sh nom_utilisateur -
```

Si vous avez déjà téléchargé le dépôt, lancez le script directement :

```bash
chmod +x provision-macos-nix.sh
./provision-macos-nix.sh nom_utilisateur -
```

Le premier mot de passe demandé par `sudo` est **celui de la session administrateur déjà ouverte**. Le script demandera ensuite le mot de passe du **nouveau compte** lors de sa création ; macOS peut aussi redemander celui de l'administrateur. Le `-` évite d'inscrire le mot de passe du nouveau compte dans la commande ou de l'exposer dans ses arguments.

Le script accepte aussi `./provision-macos-nix.sh nom_utilisateur mot_de_passe`, mais ce format peut exposer le mot de passe dans l'historique du terminal et la liste des processus. Le compte ne doit pas déjà exister. Il est créé comme utilisateur standard. À la fin, le script affiche l'état de son Secure Token.

## Références

- [Installation officielle de Nix sur macOS](https://nixos.org/download/)
- [Installation de Homebrew](https://docs.brew.sh/Installation)
- [Paquet Homebrew Microsoft Office](https://formulae.brew.sh/cask/microsoft-office)
- [Secure Token sur macOS](https://support.apple.com/guide/deployment/use-secure-token-bootstrap-token-and-volume-ownership-dep24dbdcf9e/web)
