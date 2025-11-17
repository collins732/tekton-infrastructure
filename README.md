# 🏗️ VulnScanner Infrastructure

Infrastructure as Code pour déployer VulnScanner sur Azure avec Terraform.

## 🏛️ Architecture

- **Cloud Provider**: Azure
- **OS**: Ubuntu 22.04 LTS
- **Runtime**: Node.js 20.x
- **Framework**: Next.js 16
- **Reverse Proxy**: Nginx
- **Région**: France Central
- **VM Size**: Standard_B2s (2 vCPU, 4 GB RAM)

## 📋 Prérequis

### 1. Azure CLI
```bash
# Installation (Windows)
winget install Microsoft.AzureCLI

# Vérification
az --version

# Connexion
az login
```

### 2. Terraform
```bash
# Installation (Windows avec Chocolatey)
choco install terraform

# Vérification
terraform --version
```

### 3. Clé SSH
```bash
# Générer une clé SSH si vous n'en avez pas
ssh-keygen -t rsa -b 4096 -C "votre-email@example.com"

# Vérifier que la clé existe
ls ~/.ssh/id_rsa.pub
```

## 🚀 Déploiement

### 1. Cloner le repo et naviguer vers le dossier
```bash
cd infra/terraform
```

### 2. Initialiser Terraform
```bash
terraform init
```

### 3. Vérifier le plan de déploiement
```bash
terraform plan
```

### 4. Déployer l'infrastructure
```bash
terraform apply
```

Répondez `yes` pour confirmer.

### 5. Récupérer les informations de connexion

Terraform affichera :
```
Outputs:

nextjs_url = "http://4.233.106.136"
public_ip = "4.233.106.136"
ssh_command = "ssh azureuser@4.233.106.136"
```

### 6. ⏱️ Attendre la fin de l'installation (10 minutes)

Le script `cloud-init` installe automatiquement :
- Node.js 20.x
- Clone le repo GitHub
- Installe les dépendances npm
- Build Next.js
- Configure Nginx
- Démarre les services

**Suivre la progression en temps réel :**
```bash
ssh azureuser@<IP_PUBLIQUE>
sudo tail -f /var/log/cloud-init-output.log
```

**Vérifier que cloud-init a terminé :**
```bash
cloud-init status
```

### 7. 🌐 Accéder à l'application

**URL principale (port 80 - recommandé) :**
```
http://<IP_PUBLIQUE>
```

**URL alternative (port 3000 - direct Next.js) :**
```
http://<IP_PUBLIQUE>:3000
```

## 🔧 Configuration

### Variables personnalisables

Éditez `terraform/variables.tf` pour modifier :

| Variable | Description | Défaut |
|----------|-------------|--------|
| `resource_group_name` | Nom du resource group | `rg-vulnscanner` |
| `location` | Région Azure | `francecentral` |
| `vm_size` | Taille de la VM | `Standard_B2s` |
| `admin_username` | Utilisateur SSH | `azureuser` |
| `github_repo_url` | Repo de l'application | `https://github.com/vulne-app/vulnscanner-app.git` |

### Ports ouverts (NSG)

| Port | Service | Description |
|------|---------|-------------|
| 22 | SSH | Connexion SSH |
| 80 | HTTP | Nginx reverse proxy |
| 3000 | Next.js | Accès direct (optionnel) |

## 📂 Structure du projet

```
infra/
├── README.md              # Documentation (ce fichier)
├── terraform/
│   ├── main.tf           # VM et ressources principales
│   ├── network.tf        # VNet, subnet, IP publique, NSG
│   ├── variables.tf      # Variables configurables
│   ├── providers.tf      # Configuration Azure provider
│   └── outputs.tf        # Outputs (IP, URL, SSH)
└── scripts/
    └── setup-vm.sh       # Script d'installation cloud-init
```

## 🛠️ Commandes utiles

### Connexion SSH
```bash
ssh azureuser@<IP_PUBLIQUE>
```

### Vérifier les services
```bash
# Statut Next.js
sudo systemctl status nextjs

# Statut Nginx
sudo systemctl status nginx

# Logs Next.js en temps réel
sudo journalctl -u nextjs -f

# Logs cloud-init
sudo tail -f /var/log/cloud-init-output.log
```

### Redémarrer les services
```bash
# Redémarrer Next.js
sudo systemctl restart nextjs

# Redémarrer Nginx
sudo systemctl restart nginx
```

### Tester depuis la VM
```bash
# Tester Next.js (port 3000)
curl http://localhost:3000

# Tester Nginx (port 80)
curl http://localhost:80
```

## 🗑️ Détruire l'infrastructure

⚠️ **Attention** : Cette commande supprime TOUTES les ressources Azure !

```bash
cd terraform
terraform destroy
```

Répondez `yes` pour confirmer.

## 🐛 Troubleshooting

### L'application n'est pas accessible après le déploiement

**1. Vérifier que cloud-init a terminé :**
```bash
ssh azureuser@<IP_PUBLIQUE>
cloud-init status
```

Si `status: done`, c'est bon. Si `status: running`, attendez encore.

**2. Vérifier que Next.js tourne :**
```bash
sudo systemctl status nextjs
```

Vous devez voir `Active: active (running)`.

**3. Vérifier que Nginx tourne :**
```bash
sudo systemctl status nginx
```

**4. Tester localement depuis la VM :**
```bash
curl http://localhost:3000  # Next.js direct
curl http://localhost:80    # Nginx
```

### Le port 3000 est bloqué par mon pare-feu

➡️ **Solution** : Utilisez le port 80 (HTTP standard)
```
http://<IP_PUBLIQUE>
```

Le port 80 est rarement bloqué par les pare-feu d'entreprise/réseau.

### Erreur : "Could not find SSH key"

Vérifiez que votre clé SSH existe :
```bash
ls ~/.ssh/id_rsa.pub
```

Si elle n'existe pas, générez-en une :
```bash
ssh-keygen -t rsa -b 4096 -C "votre-email@example.com"
```

### Redéploiement après modification du code

Après un `git push` sur le repo de l'application :

```bash
ssh azureuser@<IP_PUBLIQUE>
cd /opt/vulnscanner/app
git pull
npm install
npm run build
sudo systemctl restart nextjs
```

## 📊 Architecture réseau

```
Internet
   │
   ▼
Azure Public IP (4.x.x.x)
   │
   ▼
Network Security Group (NSG)
├─ Port 22  → SSH ✅
├─ Port 80  → HTTP ✅
└─ Port 3000 → Next.js ✅
   │
   ▼
Virtual Network (10.0.0.0/16)
   │
   ▼
Subnet (10.0.1.0/24)
   │
   ▼
Network Interface (NIC)
   │
   ▼
Ubuntu VM (10.0.1.4)
├─ Nginx :80 ──→ localhost:3000
└─ Next.js :3000
```

## 🔄 Workflow de développement

1. **Push du code** sur GitHub (repo `vulnscanner-app`)
2. **Déploiement infra** : `terraform apply`
3. **Attendre 10 min** : cloud-init fait tout automatiquement
4. **Tester** : Ouvrir `http://<IP_PUBLIQUE>`
5. **Modifications** : Push → SSH → `git pull` → `npm run build` → `restart`

## 👥 Équipe


- Eugène - 
- Collins 
- Marlene 
- Mimi 