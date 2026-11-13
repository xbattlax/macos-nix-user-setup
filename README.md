# Provisionnement macOS : compte, Nix et applications

Ce script crée un compte utilisateur standard et installe, si nécessaire :

- Homebrew
- Google Chrome
- Claude Desktop et Claude Code
- Microsoft Office pour Mac (applications locales)
- Adobe Creative Cloud
- DisplayLink Manager pour les stations d’accueil compatibles
- Webex
- ChatGPT
- Codex (application Mac et outil en ligne de commande)

Nix est optionnel et reporté par défaut : l’installateur officiel a échoué sur un volume `/nix` partiellement créé lors d’un déploiement. Il ne sert pas à installer ces applications.

Les applications sont installées pour le Mac via Homebrew. Nix est disponible pour les comptes de la machine, mais le script ne gère pas les applications avec nix-darwin.

Si le téléchargement ou l'installation d'une application échoue, le script passe à la suivante et crée quand même le compte. Il affiche à la fin la liste des applications à reprendre. Si Homebrew ne peut pas être installé, la création du compte continue également.

## Prérequis

- macOS 14 ou plus récent pour le paquet Office. Homebrew prend officiellement en charge macOS 15 ou plus récent sur Apple Silicon ; macOS 14 peut fonctionner sans être pris en charge.
- Une session administrateur avec accès Internet et un terminal interactif.
- Une licence Microsoft adaptée pour activer Office, un compte Adobe pour Creative Cloud et les comptes nécessaires à Claude et Webex.

## Utilisation

Depuis une session administrateur macOS, remplacez `nom_utilisateur` par le nom court du nouveau compte, puis exécutez cette commande dans le Terminal, **sans `sudo`** :

```bash
curl -fsSL 'https://github.com/xbattlax/macos-nix-user-setup/raw/refs/heads/main/provision-macos-nix.sh?raw=1' -o provision-macos-nix.sh && bash provision-macos-nix.sh nom_utilisateur -
```

Si vous avez déjà téléchargé le dépôt, lancez le script directement :

```bash
chmod +x provision-macos-nix.sh
./provision-macos-nix.sh nom_utilisateur -
```

Si le compte existe déjà et que seules les applications manquent, relancez le script avec `--apps-only` :

```bash
bash provision-macos-nix.sh --apps-only
```

Ce mode ne relance pas Nix et ne modifie aucun compte utilisateur.
Il peut être relancé après un échec de téléchargement pour installer les applications manquantes.

Pour activer volontairement l’installation de Nix après diagnostic du volume `/nix` :

```bash
JEF_INSTALL_NIX=1 bash provision-macos-nix.sh nom_utilisateur -
```

L’installation normale reporte Nix et installe Homebrew, les applications, puis crée le compte standard. Diagnostiquer Nix séparément avant de relancer son installateur ; ne pas effacer le volume `/nix` à l’aveugle.

Le premier mot de passe demandé par `sudo` est **celui de la session administrateur déjà ouverte**. Le script demandera ensuite le mot de passe du **nouveau compte** lors de sa création ; macOS peut aussi redemander celui de l'administrateur. Le `-` évite d'inscrire le mot de passe du nouveau compte dans la commande ou de l'exposer dans ses arguments.

Le script accepte aussi `./provision-macos-nix.sh nom_utilisateur mot_de_passe`, mais ce format peut exposer le mot de passe dans l'historique du terminal et la liste des processus. Le compte ne doit pas déjà exister. Il est créé comme utilisateur standard. À la fin, le script affiche l'état de son Secure Token.

Après l’installation de DisplayLink Manager, redémarrez le Mac. À la première connexion du nouvel utilisateur, ouvrez DisplayLink Manager, activez son lancement automatique et accordez-lui l’autorisation « Enregistrement de l’écran » dans Réglages système. Branchez la station d’accueil et vérifiez les écrans. Cette autorisation macOS demande une action dans la session utilisateur.

## Références

- [Installation officielle de Nix sur macOS](https://nixos.org/download/)
- [Installation de Homebrew](https://docs.brew.sh/Installation)
- [Paquet Homebrew Microsoft Office](https://formulae.brew.sh/cask/microsoft-office)
- [Paquet Homebrew Creative Cloud](https://formulae.brew.sh/cask/adobe-creative-cloud)
- [Paquet Homebrew DisplayLink](https://formulae.brew.sh/cask/displaylink)
- [Paquet Homebrew Webex](https://formulae.brew.sh/cask/webex)
- [Paquet Homebrew ChatGPT](https://formulae.brew.sh/cask/chatgpt)
- [Paquet Homebrew Codex CLI](https://formulae.brew.sh/cask/codex)
- [Paquet Homebrew Codex App](https://formulae.brew.sh/cask/codex-app)
- [Configuration officielle de DisplayLink Manager](https://support.displaylink.com/knowledgebase/articles/1932214-displaylink-manager-app-for-macos-introduction-in)
- [Secure Token sur macOS](https://support.apple.com/guide/deployment/use-secure-token-bootstrap-token-and-volume-ownership-dep24dbdcf9e/web)
