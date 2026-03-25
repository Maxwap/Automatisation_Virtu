

````
# 🚀 Automatisation de l'infrastructure Debian 13 sur Proxmox VE

Ce dépôt contient la documentation et le code Terraform pour créer un modèle (Template) Debian 13 et déployer automatiquement des machines virtuelles via Cloud-Init.

---

## 🛠️ Partie 1 : Création du Template Proxmox (ID 900)

Exécutez ces commandes en SSH sur votre nœud Proxmox (`pve-01`).

### 1.1 Prérequis
Installez l'outil `libguestfs-tools` pour modifier l'image sans l'allumer.

```bash
apt update
apt install -y libguestfs-tools
````

### 1.2 Téléchargement et Personnalisation de l'image

Nous allons télécharger l'image Cloud officielle et injecter le paquet `qemu-guest-agent`.

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

### 1.3 Déploiement de la VM Template dans Proxmox

Création de la structure de la VM, importation du disque et liaison du lecteur Cloud-Init.

Bash

```
# 1. Créer la VM (ID 900, Nom template13, 2 Cores, 2Go RAM, Activation Agent)
qm create 900 --name "template13" --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0 --agent 1

# 2. Importer le disque dans le stockage local (local-lvm)
qm disk import 900 /tmp/debian-13-genericcloud-amd64.qcow2 local-lvm

# 3. Attacher le disque à la VM en tant que contrôleur scsi0
qm set 900 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-900-disk-0

# 4. Ajouter le lecteur Cloud-Init (indispensable pour Terraform)
qm set 900 --ide2 local-lvm:cloudinit

# 5. Forcer le Boot sur le disque scsi0 et activer l'affichage VGA classique
qm set 900 --boot c --bootdisk scsi0
qm set 900 --vga std
```

### 1.4 Vérification et Conversion en Template

Bash

```
# Allumer la VM pour test
qm start 900
```

> **Vérification :** Allez dans l'interface Web de Proxmox > VM 900 > Onglet **Summary**. L'adresse IP locale doit remonter automatiquement (Preuve que le QEMU Agent fonctionne).

Une fois validé, éteignez la machine et convertissez-la en Template :

Bash

```
# Éteindre proprement la VM
qm stop 900

# Convertir en Template Proxmox
qm template 900

# Nettoyer le fichier temporaire
rm /tmp/debian-13-genericcloud-amd64.qcow2
```

---

## 🏗️ Partie 2 : Déploiement avec Terraform

Une fois le Template `900` créé, utilisez Terraform depuis votre machine locale (`nico@Templates`) pour cloner et déployer vos machines.

### 2.1 Configuration du fichier `main.tf`

Créez ou modifiez votre fichier `main.tf` en y injectant votre clé publique `id_ansible.pub`.

Terraform

```
resource "proxmox_virtual_environment_vm" "debian_vm" {
  name      = "debian13-prod"
  node_name = "pve-01"
  vm_id     = 104 # ID de la nouvelle VM à créer

  # On clone notre template 900
  clone {
    vm_id = 900
  }

  initialization {
    ip_config {
      ipv4 {
        address = "10.0.10.104/24"
        gateway = "10.0.10.1" # Mettez votre passerelle réelle
      }
    }

    user_account {
      username = "debian"
      # On injecte la clé id_ansible.pub récupérée via : cat ~/.ssh/id_ansible.pub
      keys     = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO8OyAEo7WzXm7V3rjnl9J6FH5Zi8sBU5kNZQn9XkFmQ nico@Templates"]
    }
  }

  cpu {
    cores = 2
  }

  memory {
    dedicated = 2048
  }
}
```

### 2.2 Déploiement

Lancez les commandes Terraform pour appliquer la configuration :

Bash

```
terraform init
terraform plan
terraform apply
```

### 2.3 Connexion SSH à la nouvelle machine

Comme la clé par défaut (`id_rsa`) n'existe pas chez vous, forcez SSH à utiliser votre clé `id_ansible` pour vous connecter :

Bash

```
ssh -i ~/.ssh/id_ansible debian@10.0.10.104
```
