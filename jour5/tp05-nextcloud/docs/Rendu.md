
# RENDU — TP05 — Nextcloud sur AWS

  

> **Instructions de remplissage** : ce fichier est le `docs/RENDU.md` à livrer dans votre zip. Copiez-le tel quel dans votre repo à la racine de `docs/RENDU.md`, puis remplissez **toutes** les sections ci-dessous. Les `<!-- remplir ici -->` et les `TODO` doivent avoir disparu à la remise.

  

---

  

## 🟥 Rappel critique — avant de zipper

  

> 🟥 **Ne jamais committer** :

>

> - `*.tfvars` (sauf les `*.tfvars.example`)

> - `*.tfstate` et `*.tfstate.backup`

> - Le dossier `.terraform/`

> - Aucun mot de passe en clair (DB, admin Nextcloud, clé AWS, token GitHub)

> - Aucune clé privée (`*.pem`, `id_rsa`, etc.)

>

> 🔹 Vérifiez une dernière fois avant le zip :

>

> ```bash

> cd tp05-nextcloud

> grep -rE "(password|secret|AKIA)" --include="*.tf" --include="*.tfvars" . | grep -v example

> # Doit retourner 0 ligne

> ```

  

---

  

## Section 1 — Identification de l'équipe

  

**Numéro d'équipe** : `groupe 2`

**Nom de code de l'équipe** *(optionnel)* : `TODO`

**Date de rendu** : 12/06/2026

  

### Membres

  

| Prénom Nom | Rôle assigné | Email | Compte GitHub |

| ------------ | -------------- | ------- | --------------- |

| `<!-- Pierrick -->` | Platform Lead (Rôle 1) | `p.monnier@ecole-ipssi.net` |[ `@ghuser` |](https://github.com/PMIPSSI/IPSSI-PM/tree/main/jour5/tp05-nextcloud)
https://github.com/PMIPSSI/IPSSI-PM/tree/main/jour5/tp05-nextcloud
| `<!-- Akram -->` | Network Engineer (Rôle 2) |  'a.didi@ecole-ipssi.net' 
https://github.com/PMIPSSI/IPSSI-PM/tree/main/jour5/tp05-nextcloud

| `<!-- Ayoub -->` | Compute Engineer (Rôle 3) | | | 'a.hasni@ecole-ipssi.net' 
https://github.com/PMIPSSI/IPSSI-PM/tree/main/jour5/tp05-nextcloud  

| `<!-- Raphaël -->` | Data Engineer (Rôle 4) | | |  'r.michaux@ecole-ipssi.net' 
https://github.com/PMIPSSI/IPSSI-PM/tree/main/jour5/tp05-nextcloud  

| `<!-- Ayoub -->` | Security Engineer (Rôle 5) | | | 'a.hasni@ecole-ipssi.net'  
https://github.com/PMIPSSI/IPSSI-PM/tree/main/jour5/tp05-nextcloud

  

> 🔷 Équipe à 4 personnes : indiquez qui a fusionné le rôle Security dans le rôle Platform.

>

> *Exemple : "Équipe à 4 — le Platform Lead a également porté le module `security`."*

  

---

  

## Section 2 — Résumé architecture

  
L'utilisateur accède à Nextcloud en HTTPS via un équilibreur de charge public (ALB) qui relaie le trafic vers une instance EC2 isolée dans un sous-réseau privé.
L'application stocke ses métadonnées sur une base de données RDS PostgreSQL (sous-réseau DB) et les fichiers utilisateurs sur un bucket S3 dédié.
Le réseau est strictement segmenté et chaque composant est protégé par son propre pare-feu (Security Group) limitant les flux au strict nécessaire.
L'intégralité des données persistantes (RDS, S3) et des mots de passe (Secrets Manager) est chiffrée par une clé KMS centralisée.
L'instance EC2 s'authentifie de manière transparente et sécurisée auprès d'AWS (S3, Secrets) grâce à un rôle IAM, sans aucune clé d'accès en dur.


  



  

  

### Schéma Mermaid (à jour avec ce qui a été réellement déployé)

  
![[Pasted image 20260612142151.png]]

> 🔹 Astuce : copiez le schéma du fichier `ARCHITECTURE.md` que vous avez maintenu pendant la journée.

  

---

  

## Section 3 — Arbitrages techniques réalisés

  

Listez **au minimum 3 arbitrages** que vous avez faits pendant le TP (choix structurant, alternative considérée, raison du choix, conséquence).

  

### Arbitrage 1

  
Ce qu'on a fait : On a mis un Auto Scaling Group (ASG), mais on l'a bloqué à 1 seule instance.

Pourquoi ce choix: Si on mettait 2 instances Nextcloud en même temps derrière l'ALB, elles essaieraient d'écrire sur les mêmes fichiers dans le bucket S3 en même temps. Sans un serveur Redis pour gérer les files d'attente (ce qu'on n'a pas dans ce TP), la base de données planterait.

Le compromis : On sacrifie la "Haute Disponibilité" absolue pour éviter la corruption de données. 

  

### Arbitrage 2

  
Les mots de passe qui se détruisent tout de suite

Ce qu'on a fait : Dans le module Security, on a forcé recovery_window_in_days = 0 sur Secrets Manager.

Pourquoi on a fait ça : Par défaut, AWS garde un secret supprimé pendant 30 jours (au cas où). Mais en TP, on fait plein de terraform destroy et terraform apply. Si on avait laissé 30 jours, au deuxième apply, AWS nous aurais indiquerune erreur  "ce nom de mot de passe existe déjà dans la corbeille".

Le compromis : On supprime la sécurité anti-erreur d'AWS pour pouvoir coder et tester plus vite. 

  

### Arbitrage 3

  Les Security Groups liés entre eux (plutôt que des IP)

Ce qu'on a fait : Au lieu de dire "La base de données accepte les IP de tout le sous-réseau App", on a dit "La base de données n'accepte que le Security Group de l'App".

Pourquoi on a fait ça : C'est le principe du "Moindre Privilège" absolu (Zero Trust).

Le compromis : Ça rend le code Terraform un peu plus long et complexe à écrire (car il faut utiliser les ID des groupes), mais c'est beaucoup plus sécurisé.



  

---

  

## Section 4 — Retour sur les interfaces inter-modules

  

Les interfaces (variables + outputs) étaient figées au kick-off. Répondez aux questions suivantes.

  

**Quelle interface a été la plus délicate à stabiliser ?**

  **L'interface entre les modules Security et Data.** Il y avait un risque de boucle de dépendance : le module de sécurité devait chiffrer les buckets S3 de Data avec la clé KMS, mais Data avait besoin de l'ARN de cette clé KMS pour se déployer. Nous l'avons résolu grâce au "late binding" en passant les ARN S3 en variables du module security dans le `main.tf` de l'environnement dev.

  

  

**Avez-vous dû modifier une interface en cours de route ? Si oui, laquelle et pourquoi ?**

Nous n'avons modifié aucune interface.

  


  

**Qu'est-ce qui a le mieux fonctionné dans la collaboration inter-modules ?**

  
Le fait de définir les outputs en premier a permis à chaque équipe d’avancer en parallèle sans attendre que les autres modules soient déployés.
  

**Qu'est-ce qui a bloqué ?**

  Les dépendances croisées entre Security et Data ont ralenti le déploiement. 

  

---

  

## Section 5 — Résultats `terraform plan` et `terraform apply`

  

Collez ici les **résumés** (pas les sorties complètes) des commandes finales exécutées depuis `envs/dev/`.

  

### `terraform plan` final

  

Plan: 0 to add, 1 to change, 0 to destroy. 

  

### `terraform apply` final

  

Apply complete! Resources: 0 added, 1 changed, 0 destroyed.

Outputs:

alb_dns_name = "TP-PMONNIER-dev-alb-986967272.eu-west-3.elb.amazonaws.com"  
nextcloud_url = "https://TP-PMONNIER-dev-alb-986967272.eu-west-3.elb.amazonaws.com"  
s3_primary_bucket_name = "grp2-tp-pmonnier-dev-nextcloud-primary"

  

### Nombre total de ressources déployées

  

**Total** : 81 ressources

  

> 🔷 Ce nombre doit correspondre à ce qui est visible dans `02-apply-success.png`.

  

---

  

## Section 6 — Checklist des 5 screenshots obligatoires

  

Les captures doivent être dans `docs/screenshots/` au format PNG. Cochez chaque case quand le fichier est présent ET lisible.

  

- [x] `01-plan-dev.png` — sortie de `terraform plan` avec la ligne `Plan: N to add, ...` visible

- [x] `02-apply-success.png` — sortie `Apply complete! Resources: N added.` + les outputs visibles

- [x] `03-nextcloud-login.png` — page de login Nextcloud dans le navigateur avec l'URL ALB visible dans la barre d'adresse

- [x] `04-file-in-s3.png` — console AWS S3 montrant un fichier uploadé depuis Nextcloud, avec le chiffrement KMS visible dans les propriétés

- [x] `05-destroy-success.png` — sortie `Destroy complete! Resources: N destroyed.`

  

> 🟡 Piège courant : les screenshots avec informations sensibles visibles. Avant de les coller dans le zip, floutez les IP publiques personnelles, les tokens, les clés AWS complètes.

> 🔹 Astuce : si une capture contient un mot de passe admin Nextcloud en clair (généré puis affiché), régénérez-la avec le mot de passe masqué ou ne l'incluez pas.

  

---

  

## Section 7 — Coût estimé

  

Estimez le coût de l'infrastructure pour 24h de fonctionnement (dev). Utilisez Infracost si possible, sinon faites un calcul manuel à partir de la [page de tarification AWS eu-west-3](https://aws.amazon.com/ec2/pricing/on-demand/).

  
| Ressource                  | Quantité | Prix unitaire (USD)  | Sous-total 24h (USD) |
| -------------------------- | -------- | -------------------- | -------------------- |
| EC2 t3.small               | 1        | 0.0228 $/h           | ~0.55 $              |
| ALB                        | 1        | 0.025 $/h            | ~0.60 $              |
| NAT Gateway                | 1        | 0.048 $/h            | ~1.15 $              |
| RDS db.t3.micro Multi-AZ   | 1        | 0.038 $/h            | ~0.91 $              |
| EBS RDS gp3                | 20 GB    | 0.118 $/GB-mois      | ~0.08 $              |
| S3 primary + logs          | ~5 GB    | 0.024 $/GB-mois      | ~0.01 $              |
| KMS CMK                    | 1        | 1.00 / mois          | ~0.03 $              |
| Secrets Manager            | 2        | 0.40 / secret / mois | ~0.02 $              |
| VPC Endpoints (S3)         | 1        | Gratuit (Gateway)    | 0.00 $               |
| **Total 24h**              |          |                      | **~3.35 $**          |
| **Extrapolation 30 jours** |          |                      | **~100.50 $**        |

  

> *Exemple : Total 24h ~= 6.10 USD, extrapolation 30 jours ~= 183 USD.*

  

**Méthode utilisée** :  calculator AWS 

  

**Commentaire** :
Pour une durée de 30 jours, le prix est assez élevé. 
  

> *Exemple : le NAT Gateway seul représente ~35% du coût — on pourrait le supprimer après le boot initial de Nextcloud en `dev` puisque l'instance n'a plus besoin de sortir d'Internet.*

  

---

  

## Section 8 — Rétrospective équipe

  

### 🟢 3 choses qui ont bien marché

  

1. Création de la NAT -->`

2. `<Création du bucket S3 -->`

3. `<Création du VPC et subnet >`

  

> *Exemple : "Le fait de figer les interfaces au kick-off nous a permis de travailler en parallèle sans se marcher dessus."*

  

### 🔴 3 choses qui ont bloqué

  

1. Erreurs dans les droits IAM

2. `< le stockage de la BDD était bloqué de 20 Go il a fallut le passer à 30 Go à peu près

3. les variables dans les différents fichier .tf 

  

> *Exemple : "Cycle de dépendance entre security et data — perdu 45 min avant de comprendre qu'il fallait passer les ARN en variable plutôt que `depends_on`."*

  

### 🔷 3 améliorations pour la prochaine fois

  

	1. Comprendre mieux le fonctionnement de git

2. Meilleur explication pour le déploiement du TP

3. Mieux détaillé les scripts

  

> *Exemple : "Installer tfsec dans le pre-commit dès le matin aurait évité 3 HIGH détectés en fin de journée."*

  

---

  

## Section 9 — Contribution individuelle par rôle

  

**Chaque membre remplit son bloc lui-même.** Soyez honnêtes — cette section sert à l'individualisation de la note.

  

> 🔷 Le hash du commit est obtenu avec `git log --oneline -1 --author="Votre Nom"` ou `git log --format='%h %s' | head -5`.

  

---

  

### Rôle 1 — Platform Lead

  

**Membre** : `<!-- Pierrick MONNIER -->`

  

**Ce que j'ai livré** :

  bootstrap/create-state-bucket.sh : Création du backend S3 et de la CMK KMS de state.

    envs/dev/main.tf, backend.tf, providers.tf : Orchestration des 4 modules et configuration du lock S3 natif (v1.10).

    Fichiers qualité : .gitignore, .pre-commit-config.yaml.


modules/security/ (Complet) : KMS CMK applicative avec alias et rotation, 3 Security Groups en syntaxe v5 (règles éclatées et référencées SG-to-SG), Secrets Manager (random_password), et IAM Role assumable par EC2 avec policies strictement limitées (Least Privilege).

    Revue et fusion de l'ensemble des Pull Requests de l'équipe.

    Orchestration du terraform apply collectif final.
  

**Ce qui m'a surpris ou frustré** :
L'intransigeance de la Key Policy de KMS. Le fait qu'un oubli de la directive "EnableRootAccountAccess" puisse bricker la clé de façon irrémédiable m'a obligé à être extrêmement méticuleux. Également, l'interdiction totale des wildcards (*) par tfsec m'a forcé à définir précisément chaque ressource S3 (bucket_arn ET bucket_arn/*).

  

**Ce que j'ai appris** :

La nouvelle fonctionnalité use_lockfile = true du backend S3 apparue avec Terraform 1.10 remplace avantageusement DynamoDB. J'ai également maîtrisé le pattern SG-to-SG (referenced_security_group_id) pour isoler des ressources comme RDS sans jamais ouvrir le port à un CIDR entier.



  

**Hash du dernier commit significatif que j'ai fait** : `<b541721 -->`

  

---

  

### Rôle 2 — Network Engineer

  

**Membre** : `<!-- Akram DIDI-->`

  

**Ce que j'ai livré** :



- `<!- mudles/networking/ locals.tf , outputs.tf, variables.tf, versions.tf , readme.md`

VPC, 6 subnets (2 pub + 2 priv app + 2 priv db), IGW, NAT, route tables, 2 VPC endpoints 


    Orchestration du terraform apply collectif final.

  

**Ce qui m'a surpris ou frustré** :

Le fonctionnement de Terraform et l'infra déployé. 

  

**Ce que j'ai appris** :

  A quoi sert et comment fonctionne Terraform.

  

**Hash du dernier commit significatif que j'ai fait** : `<33f7de0 -->`

  

---

  

### Rôle 3 — Compute Engineer

  

**Membre** : `<!Ayoub HASNI -->`

  

**Ce que j'ai livré** :

  

- `modules/compute/ redame.md , alb.tf , asg.tf , locals.tf , main.tf , outputs.tf , tls.tf , variables.tf , versions.tf -->`

- `<modules/security/iam.tf , kms.tf , main.tf , outputs.tf , secrets.tf , sg.tf , variables.tf , versions.tf ,  -->`


  

**Ce qui m'a surpris ou frustré** :

  J'ai été surpris du fonctionnement de Terraform et du gain de temps.

  

**Ce que j'ai appris** :

  Le fonctionnement de Terraform.
  

**Hash du dernier commit significatif que j'ai fait** : `<d971f7d -->`

  

---

  

### Rôle 4 — Data Engineer

  

**Membre** : `Raphaël MICHAUX -->`

  

**Ce que j'ai livré** :

  

- `modules/data/rds.tf , redame.md , main.tf , outputs.tf , s3.tf , variables.tf , versions.tf`



  

**Ce qui m'a surpris ou frustré** :

  Ce qui m'a surpris, c'est le script qu'il a fallut déployer pour pouvoir 
  créé l'infra et les notions techniques.
  

**Ce que j'ai appris** :

Comment fonctionne Terraform.

  

**Hash du dernier commit significatif que j'ai fait** : `<!-- ex: a1b2c3d -->`

  

---

  

### Rôle 5 — Security Engineer

  

**Membre** : `<!Pierrick et Ayoub" -->`

  

**Ce que j'ai livré** :

  

- 'modules/security/sg.tf , iam.tf , kms.tf , main.tf , outputs.tf , secrets.tf , sg.tf , variables.tf , versions.tf

  

**Ce qui m'a surpris ou frustré** :

  
Le déploiement de l'infra et la complexité d'utilisation de l'outil.
  

**Ce que j'ai appris** :

  Comment fonctionne Terraform 

  

**Hash du dernier commit significatif que j'ai fait** : `<!-- ex: a1b2c3d -->`

  

---

  

## Section 10 — Checklist finale avant remise

  

**L'équipe certifie collectivement que** :

  

- [x] `terraform destroy` a été exécuté avec succès dans `envs/dev/` (screenshot `05-destroy-success.png` prouve `Destroy complete!`)

- [x] La console AWS a été re-vérifiée : aucune EC2, RDS, NAT Gateway, ELB, EIP, Secret Manager, bucket S3 (hors bucket state) ne reste avec les tags de l'équipe

- [x] Aucun fichier `*.tfstate` ou `*.tfstate.backup` n'est présent dans le zip

- [x] Aucun dossier `.terraform/` n'est présent dans le zip

- [x] Aucun fichier `*.tfvars` personnel n'est présent (seul `terraform.tfvars.example` est autorisé)

- [x] Aucun secret en clair (mot de passe DB, admin, access key, token GitHub) n'est dans le code

- [x] La commande `grep -rE "(password|secret|AKIA)" --include="*.tf" . | grep -v example` retourne 0 ligne

- [x] Les 5 screenshots obligatoires sont dans `docs/screenshots/`

- [x] Le fichier `docs/RENDU.md` (ce fichier) est rempli à 100 % — plus aucun `<!-- remplir -->` ni `TODO` résiduel

- [x] Le fichier `ARCHITECTURE.md` contient un schéma Mermaid à jour

- [x] Chaque module dans `modules/` a son `README.md` (minimum : titre + description + inputs/outputs)

- [x] Le fichier `.terraform.lock.hcl` est committé (mais pas `.terraform/`)

- [x] Les commits git sont tracés par auteur (pour la notation individuelle)

- [x] Le zip est nommé exactement `tp05-nextcloud-equipe<N>.zip`

  

### Commande de packaging recommandée

  

```bash

# Depuis la racine du projet

cd ~/formation-terraform/jour5

  

# Nettoyage des artefacts lourds avant zip

find tp05-nextcloud -type d -name ".terraform" -exec rm -rf {} +

find tp05-nextcloud -name "terraform.tfstate*" -delete

find tp05-nextcloud -name "*.tfvars" ! -name "*.tfvars.example" -delete

  

# Verification finale secrets

grep -rE "(password|secret|AKIA)" tp05-nextcloud --include="*.tf" --include="*.tfvars" | grep -v example

# Doit retourner 0 ligne

  

# Zip final (en conservant le .git pour la notation individuelle)

zip -r tp05-nextcloud-equipe<N>.zip tp05-nextcloud/

  

# Verification du contenu

unzip -l tp05-nextcloud-equipe<N>.zip | head -50

```

  

---

  

## Signature de l'équipe

  

**Date de remise** : 12/06/2026 16: 30`

  

**Signataires** (tous les membres doivent cocher) :

  

- [x] `<!-- Pierrick Monnier Rôle 1 -->` — certifie l'exactitude des informations ci-dessus

- [x] `<!-- Akram DIDI Rôle 2 -->` — certifie l'exactitude des informations ci-dessus

- [x] `<!-- Ayoub HASNI Rôle 3 -->` — certifie l'exactitude des informations ci-dessus

- [x] `<!-- Raphaël MICHAUX Rôle 4 -->` — certifie l'exactitude des informations ci-dessus

- [x] `<!-- Ayoub et Pierrick 5 -->` — certifie l'exactitude des informations ci-dessus

  

> 🟢 Bravo — vous avez livré une infrastructure de production réelle en équipe. C'est exactement ce que vous ferez en entreprise. Bon courage pour la suite.