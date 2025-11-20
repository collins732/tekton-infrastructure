# VulnScanner Infrastructure

Infrastructure as Code pour le déploiement automatisé de l'application VulnScanner sur Azure.

## Membres du groupe

- Eugène
- Collins
- Marlene
- Jessica
- Walid

## Description

Cette infrastructurex configure un environnement complet sur Azure pour déployer l'application VulnScanner. Elle inclut les ressources suivantes :

- Une **Virtual Machine Ubuntu 22.04 LTS** pour héberger l'application
- Un **Virtual Network (VNet)** avec subnet pour isoler les ressources
- Une **adresse IP publique statique** pour l'accès externe
- Un **Network Security Group (NSG)** pour sécuriser les communications
- Un **serveur Nginx** configuré en reverse proxy
- Un **service systemd** pour la persistance de l'application Next.js

## Stack technique

| Composant | Version |
|-----------|---------|
| Cloud Provider | Microsoft Azure |
| OS | Ubuntu 22.04 LTS |
| Runtime | Node.js 20.x |
| Framework | Next.js 16 |
| Reverse Proxy | Nginx |
| IaC | Terraform |

## Variables

Voici les variables utilisées pour configurer cette infrastructure :

| Variable | Description | Type | Défaut |
|----------|-------------|------|--------|
| `resource_group_name` | Nom du groupe de ressources Azure | string | `rg-vulnscanner` |
| `location` | Région Azure pour les ressources | string | `francecentral` |
| `vm_size` | Taille de la machine virtuelle | string | `Standard_B2s` |
| `admin_username` | Nom d'utilisateur pour la connexion SSH | string | `azureuser` |
| `github_repo_url` | URL du repository GitHub de l'application | string | `https://github.com/vulne-app/vulnscanner-app.git` |

## Structure des fichiers

L'organisation des fichiers Terraform pour cette infrastructure est la suivante :

```
infrastructure/
├── terraform/
│   ├── main.tf          # Déclarations principales (VM, compute)
│   ├── network.tf       # Réseau virtuel, subnet, NSG, IP publique
│   ├── variables.tf     # Variables utilisées dans l'infrastructure
│   ├── outputs.tf       # Sorties des ressources Terraform
│   └── providers.tf     # Configuration du provider Azure
├── scripts/
│   └── setup-vm.sh      # Script cloud-init pour le provisionnement
├── .gitignore           # Fichiers exclus du versioning
└── README.md            # Documentation (ce fichier)
```

## Architecture réseau

| Ressource | Plage d'adresses |
|-----------|-----------------|
| Réseau Virtuel (VNet) | 10.0.0.0/16 |
| Sous-réseau principal | 10.0.1.0/24 |

### Network Security Group (NSG)

| Port | Service | Usage |
|------|---------|-------|
| 22 | SSH | Administration de la VM |
| 80 | HTTP | Accès applicatif via Nginx |
| 3000 | Next.js | Accès direct à l'application |

## Prérequis

Avant de déployer l'infrastructure, assurez-vous d'avoir :

1. **Azure CLI** installé et configuré
2. **Terraform** >= 1.5
3. Une **clé SSH** générée

### Installation et configuration

#### 1. Azure CLI

```bash
# Installation (Windows)
winget install Microsoft.AzureCLI

# Connexion à Azure
az login
```

#### 2. Terraform

```bash
# Installation (Windows avec Chocolatey)
choco install terraform

# Vérification
terraform --version
```

#### 3. Génération de la clé SSH

```bash
# Générer une paire de clés SSH (si vous n'en avez pas)
ssh-keygen -t rsa -b 4096 -C "votre-email@example.com"

# Vérifier que la clé publique existe
ls ~/.ssh/id_rsa.pub
```

**Note** : Terraform utilise automatiquement la clé publique `~/.ssh/id_rsa.pub` pour configurer l'accès SSH à la VM.

## Instructions de déploiement

### 1. Cloner le repository

```bash
git clone git@github.com:vulne-app/vulnscanner-infrastructure.git
cd vulnscanner-infrastructure
```

### 2. Configurer les variables (optionnel)

Modifiez les valeurs par défaut dans `terraform/variables.tf` si nécessaire.

### 3. Déployer l'infrastructure

```bash
cd terraform
terraform init
terraform apply
```

Confirmez le déploiement en tapant `yes` lorsque Terraform vous le demande.

### 4. Récupérer les informations de connexion

Après le déploiement, Terraform affiche les outputs :

```
Outputs:

nextjs_url = "http://4.233.106.136"
public_ip = "4.233.106.136"
ssh_command = "ssh azureuser@4.233.106.136"
```

### 5. Attendre la fin du provisionnement

Le script `cloud-init` s'exécute automatiquement au démarrage de la VM et prend environ **10 minutes** pour :

- Installer Node.js 20.x
- Cloner le repository GitHub de l'application
- Installer les dépendances npm
- Builder l'application Next.js
- Installer et configurer Nginx
- Démarrer les services systemd

**Suivre la progression en temps réel** :

```bash
ssh azureuser@<PUBLIC_IP>
sudo tail -f /var/log/cloud-init-output.log
```

**Vérifier que le provisionnement est terminé** :

```bash
cloud-init status
```

### 6. Accéder à l'application

Une fois le provisionnement terminé, l'application est accessible via :

- **Port 80 (recommandé)** : `http://<PUBLIC_IP>`
- **Port 3000 (direct)** : `http://<PUBLIC_IP>:3000`

## Vérification du déploiement

```bash
# Récupérer l'IP publique
terraform output public_ip

# Connexion SSH
ssh azureuser@<PUBLIC_IP>

# Vérifier les services
systemctl status nextjs
systemctl status nginx

# Consulter les logs
sudo journalctl -u nextjs -f
```

## Maintenance

### Mise à jour de l'application

```bash
ssh azureuser@<PUBLIC_IP>
cd /opt/vulnscanner/app
git pull
npm install
npm run build
sudo systemctl restart nextjs
```

### Destruction de l'infrastructure

```bash
cd terraform
terraform destroy
```

Confirmez la suppression en tapant `yes`. 
