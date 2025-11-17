# VulnScanner Infrastructure

Infrastructure as Code pour le déploiement automatisé de l'application VulnScanner sur Azure.

## Description

Ce repository contient la configuration Terraform permettant de provisionner une VM Azure Ubuntu 22.04 LTS avec :
- Application Next.js déployée automatiquement via cloud-init
- Nginx configuré en reverse proxy
- Services systemd pour la persistance

## Stack technique

| Composant | Version |
|-----------|---------|
| Cloud Provider | Microsoft Azure |
| OS | Ubuntu 22.04 LTS |
| Runtime | Node.js 20.x |
| Framework | Next.js 16 |
| Reverse Proxy | Nginx |
| IaC | Terraform |

## Prérequis

- Azure CLI authentifié (`az login`)
- Terraform >= 1.5
- Clé SSH générée (`~/.ssh/id_rsa.pub`)

## Déploiement

```bash
cd terraform
terraform init
terraform apply
```

Le provisionnement complet (VM + installation logicielle) prend environ 10 minutes.

## Configuration

Les variables sont définies dans `terraform/variables.tf` :

- `resource_group_name` : Nom du resource group Azure
- `location` : Région de déploiement (défaut: `francecentral`)
- `vm_size` : Taille de la VM (défaut: `Standard_B2s`)
- `github_repo_url` : Repository de l'application à déployer

## Architecture

```
Internet → Azure Public IP → NSG (22, 80, 3000) → VNet → VM Ubuntu
                                                           ├─ Nginx :80 → :3000
                                                           └─ Next.js :3000
```

### Network Security Group (NSG)

| Port | Service | Usage |
|------|---------|-------|
| 22 | SSH | Administration |
| 80 | HTTP | Accès applicatif (reverse proxy) |
| 3000 | Next.js | Accès direct (optionnel) |

## Structure

```
.
├── terraform/
│   ├── main.tf          # VM, compute resources
│   ├── network.tf       # VNet, subnet, NSG, public IP
│   ├── variables.tf     # Variables configurables
│   ├── providers.tf     # Azure provider
│   └── outputs.tf       # Outputs Terraform
└── scripts/
    └── setup-vm.sh      # Script cloud-init (provisionning VM)
```

## Post-déploiement

### Vérification du déploiement

```bash
# Récupérer l'IP publique
terraform output public_ip

# Connexion SSH
ssh azureuser@<PUBLIC_IP>

# Vérifier le statut cloud-init
cloud-init status

# Vérifier les services
systemctl status nextjs
systemctl status nginx
```

### Logs

```bash
# Logs cloud-init
sudo tail -f /var/log/cloud-init-output.log

# Logs applicatifs
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
terraform destroy
```

## Troubleshooting

**Application inaccessible**
1. Vérifier que cloud-init a terminé : `cloud-init status`
2. Vérifier les services : `systemctl status nextjs nginx`
3. Tester localement : `curl http://localhost:3000`

**Erreur clé SSH**
Terraform requiert `~/.ssh/id_rsa.pub`. Générer si nécessaire :
```bash
ssh-keygen -t rsa -b 4096
``` 