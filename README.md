
# 🚀 Automatisation de l'Infrastructure PostgreSQL Haute Disponibilité (HA) sur Proxmox VE

Ce dépôt contient l'automatisation complète pour déployer un cluster de bases de données **PostgreSQL 16/17** hautement disponible, géré par **HAProxy** sur un environnement **Proxmox VE** en combinant Terraform, Ansible et Cloud-Init.

---

## 🛠️ Partie 1 : Création du Template Debian 13 (ID 9000) sur Proxmox

Exécutez ces commandes en SSH directement sur votre nœud Proxmox (`pve-01`).

### 1.1 Prérequis
Installez l'outil de customisation d'images disque :
```bash
apt update
apt install -y libguestfs-tools
````

### 1.2 Téléchargement et Personnalisation de l'image Cloud

Nous téléchargeons l'image officielle Debian 13 Generic Cloud et injectons le `qemu-guest-agent` (nécessaire pour remonter l'adresse IP à l'interface Proxmox).

Bash

```
cd /tmp

# Télécharger l'image officielle Debian 13 Generic Cloud
wget [https://cloud.debian.org/images/cloud/trixie/latest/debian-13-genericcloud-amd64.qcow2](https://cloud.debian.org/images/cloud/trixie/latest/debian-13-genericcloud-amd64.qcow2)

# Injecter et activer le QEMU Guest Agent à l'intérieur de l'image .qcow2
virt-customize -a debian-13-genericcloud-amd64.qcow2 \
  --install qemu-guest-agent \
  --run-command "systemctl enable qemu-guest-agent"
```

### 1.3 Déploiement du Template Proxmox

Bash

```
# 1. Créer la VM (ID 9000, Nom template-debian13, 2 Cores, 2Go RAM)
qm create 9000 --name "template-debian13" --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0 --agent 1

# 2. Importer le disque dans le stockage local (local-lvm)
qm disk import 9000 /tmp/debian-13-genericcloud-amd64.qcow2 local-lvm

# 3. Attacher le disque et configurer le boot
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0
qm set 9000 --ide2 local-lvm:cloudinit
qm set 9000 --boot c --bootdisk scsi0
qm set 9000 --vga std

# 4. Convertir en modèle (Template) et nettoyer
qm template 9000
rm /tmp/debian-13-genericcloud-amd64.qcow2
```

---

## 🏗️ Partie 2 : Déploiement des VM avec Terraform

Depuis votre machine de déploiement (`Templates`), clonez le template `9000` pour créer vos serveurs (Master `10.0.10.101`, Slaves, et HAProxy `10.0.10.104`).

### 2.1 Exemple de bloc `main.tf`

Terraform

```
resource "proxmox_virtual_environment_vm" "pg_master" {
  name      = "pg-master"
  node_name = "pve-01"
  vm_id     = 101 # ID attribué sur Proxmox

  clone {
    vm_id = 9000 # ID du Template créé plus haut
  }

  initialization {
    ip_config {
      ipv4 {
        address = "10.0.10.101/24"
        gateway = "10.0.10.1"
      }
    }

    user_account {
      username = "debian"
      keys     = ["VOTRE_CLE_PUBLIQUE_SSH_ICI"] # Contenu de ~/.ssh/id_ansible.pub
    }
  }
}
```

### 2.2 Exécution de Terraform

Bash

```
terraform init
terraform plan
terraform apply
```

---

## ⚙️ Partie 3 : Provisioning et Configuration Logicielle avec Ansible

Une fois les VM démarrées, Ansible prend le relais pour configurer PostgreSQL, la réplication Streaming et le Load Balancing.

### 3.1 Architecture du projet Ansible

Notre dossier Ansible est structuré de la manière suivante :

- `inventory.ini` : Contient les IP de nos machines (Master, Slaves, HAProxy).
    
- `deploy_cluster.yml` : Le Playbook principal qui appelle nos rôles.
    
- `roles/` : Contient la logique d'installation.
    

### 3.2 L'inventaire (`inventory.ini`)

Ini, TOML

```
[master]
pg-master ansible_host=10.0.10.101 ansible_user=debian

[slaves]
pg-slave-1 ansible_host=10.0.10.102 ansible_user=debian
pg-slave-2 ansible_host=10.0.10.103 ansible_user=debian

[haproxy]
balancer ansible_host=10.0.10.104 ansible_user=debian
```

### 3.3 Lancement du déploiement Ansible

Bash

```
ansible-playbook -i inventory.ini deploy_cluster.yml --private-key=~/.ssh/id_ansible
```

### ✅ Actions automatisées par Ansible :

- **Sur le Master & les Slaves :** Installation de PostgreSQL 16/17, ouverture des connexions réseaux externes.
    
- **Sur les Slaves :** Initialisation de la réplication à chaud (Streaming Replication).
    
- **Sur le HAProxy :** Routage du trafic vers le Master sain avec tests de santé applicatifs (Health Checks).
