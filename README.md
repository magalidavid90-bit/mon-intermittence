# Mon Intermittence

Outil de suivi pour les intermittents du spectacle (annexes 8 et 10) : compteur des 507 heures, date anniversaire, projection avec les dates prévues, lecture automatique des AEM en PDF, employeurs, congés spectacles, estimation de l'allocation.

- **Appli web installable** (PWA) : icône sur l'écran d'accueil, fonctionne hors ligne.
- **Données sur l'appareil** de l'utilisateur (localStorage) : aucun serveur, aucun compte. Sauvegarde par export/import d'un fichier.
- **Lecture des PDF sans IA**, sur l'appareil, avec pdf.js (`vendor/`).
- **Version gratuite / complète** : abonnement annuel de 9,90 € (reconduction tacite), vendu par Polar (revendeur officiel), déverrouillage par clé de licence Polar.

## Fichiers

| Fichier | Rôle |
|---|---|
| `index.html` | L'application complète (HTML, CSS, JavaScript) |
| `sw.js` | Fonctionnement hors ligne |
| `manifest.webmanifest`, `icons/` | Installation sur téléphone |
| `vendor/` | pdf.js (lecture des PDF) |
| `supabase.sql` | À coller une fois dans Supabase pour la synchronisation |
| `mentions-legales.html`, `cgv.html`, `confidentialite.html` | Pages légales, à compléter |

## Réglages de la vente

En haut de la section `CONFIGURATION DE LA VENTE` dans `index.html` :

- `ventesOuvertes` : `false` tant que la vente n'est pas ouverte (le bouton d'achat est remplacé par « Version complète bientôt disponible » ; la saisie d'une clé reste possible). Passer à `true` pour vendre.
- `prix`, `duree` : prix et durée affichés (« 9,90 € par an »)
- `lienAchat` : lien d'achat Polar
- `polarOrgId` : identifiant de l'organisation Polar (activation et vérification des clés)
- `lecturesGratuites` : nombre de lectures automatiques offertes
- `cleTest` : clé d'essai `ESSAI-2026`, acceptée **uniquement en local** (localhost / 127.0.0.1)
- `supabaseUrl`, `supabaseCle` : synchronisation, option future (vide = désactivée et invisible)

## Clés de licence (Polar)

- Activation : `POST https://api.polar.sh/v1/customer-portal/license-keys/activate` (`key`, `organization_id`, `label`), 2 appareils maximum par clé (`CONFIG.appareilsMax`, à garder identique à la limite d'activation réglée dans Polar).
- Revérification au plus une fois par semaine si l'appareil est en ligne (`.../validate` avec `activation_id`). Clé révoquée, expirée ou appareil libéré → retour à la version gratuite. Hors ligne ou erreur réseau : la licence est conservée.
- Si Polar indique une date d'expiration (`expires_at`), elle est affichée et respectée.
- Après paiement, Polar renvoie vers `?achat=ok` : l'appli remercie et ouvre directement le champ de saisie de la clé.
- Le client libère un appareil et résilie son abonnement depuis son espace client Polar. À la fin de l'abonnement, Polar désactive la clé : l'appli repasse en version gratuite à la vérification suivante.

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

## Synchronisation téléphone + ordinateur (option future, désactivée)

- Chiffrée sur l'appareil (AES-GCM) avec un code de 20 caractères généré par l'appli. Le serveur ne reçoit qu'un paquet illisible, sans nom ni e-mail.
- Le premier appareil active la synchronisation et affiche le code ; les autres appareils saisissent ce code (Plus › Réglages › Synchronisation).
- Si les deux appareils ont été modifiés en même temps, les contrats sont fusionnés (les suppressions sont respectées).
- Mise en place : créer un projet Supabase (région Europe), coller `supabase.sql` dans SQL Editor, puis reporter l'adresse du projet et la clé publique dans `supabaseUrl` et `supabaseCle`.
