# Mon Intermittence

Outil de suivi pour les intermittents du spectacle (annexes 8 et 10) : compteur des 507 heures, date anniversaire, projection avec les dates prévues, lecture automatique des AEM en PDF, employeurs, congés spectacles, estimation de l'allocation.

- **Appli web installable** (PWA) : icône sur l'écran d'accueil, fonctionne hors ligne.
- **Données sur l'appareil** de l'utilisateur (localStorage) : aucun serveur, aucun compte. Sauvegarde par export/import d'un fichier.
- **Lecture des PDF sans IA**, sur l'appareil, avec pdf.js (`vendor/`).
- **Version gratuite / complète** : déverrouillage par clé de licence (plateforme de paiement à choisir : Lemon Squeezy n'accepte plus de nouveaux vendeurs).

## Fichiers

| Fichier | Rôle |
|---|---|
| `index.html` | L'application complète (HTML, CSS, JavaScript) |
| `sw.js` | Fonctionnement hors ligne |
| `manifest.webmanifest`, `icons/` | Installation sur téléphone |
| `vendor/` | pdf.js (lecture des PDF) |
| `mentions-legales.html`, `cgv.html`, `confidentialite.html` | Pages légales, à compléter |

## Réglages de la vente

En haut de la section `CONFIGURATION DE LA VENTE` dans `index.html` :

- `prix` : prix affiché
- `lienAchat` : lien de paiement Lemon Squeezy
- `produitId` : identifiant du produit Lemon Squeezy (vérification des clés)
- `lecturesGratuites` : nombre de lectures automatiques offertes
- `cleTest` : clé d'essai, valable seulement tant que `produitId` est vide

## À mettre à jour chaque année

- **1er janvier** : SMIC (horaire et mensuel) et plafond mensuel de la Sécurité sociale (`BAREME_DEFAUT`).
- **1er juillet** : revalorisation des allocations (vérifier l'AJ minimale et les planchers).
- Après chaque mise à jour, changer `VERSION` dans `sw.js` pour que les téléphones récupèrent la nouvelle version.

Les calculs sont des estimations à partir des règles publiques de l'assurance chômage ; ils ne remplacent pas les décisions de France Travail.

## Éditeur et diffusion

- Éditrice et vendeuse : **Altéa RH** (compte de paiement d'Altéa RH, plateforme à choisir).
- Partenaire de diffusion : **Studio Concorde**, qui met un bouton vers l'appli sur son site.

Code du bouton à transmettre au webmaster de Studio Concorde :

```html
<a href="https://magalidavid90-bit.github.io/mon-intermittence/" target="_blank" rel="noopener"
   style="display:inline-block;background:#C8102E;color:#fff;padding:12px 22px;border-radius:10px;font-weight:700;text-decoration:none">
  Mon Intermittence · suivre mes 507 h
</a>
```
