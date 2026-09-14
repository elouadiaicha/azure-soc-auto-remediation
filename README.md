# Module Infrastructure

Ce module déploie l'infrastructure réseau utilisée pour le projet Mini-SOC Azure.

## Ressources

Le module utilise le Resource Group existant :

- Resource Group : `rg-DZ`

Il crée :

- VNet : `vnet-soc-demo`
- NSG : `nsg-soc-demo`

## Objectif

Le NSG sert de cible pour la simulation d'un incident de sécurité.

Une règle dangereuse autorisant le port SSH `22` depuis Internet sera créée volontairement lors de la simulation.

Microsoft Sentinel devra détecter cette modification et la partie remédiation devra supprimer automatiquement la règle dangereuse.

## Outputs disponibles

Le module expose :

- `resource_group_name`
- `resource_group_id`
- `vnet_name`
- `vnet_id`
- `nsg_name`
- `nsg_id`

Ces outputs peuvent être utilisés par les modules Sentinel et Remediation.

## Déploiement

Depuis le dossier `terraform` :

```powershell
terraform init
terraform validate
terraform plan
terraform apply