# script for self-service lab for NSG/ASG
# original from https://docs.microsoft.com/en-us/learn/modules/secure-and-isolate-with-nsg-and-service-endpoints/3-exercise-network-security-groups

wget -N https://raw.githubusercontent.com/MicrosoftDocs/mslearn-secure-and-isolate-with-nsg-and-service-endpoints/master/cloud-init.yml

for i in {1..5}
do az vm create \
    --resource-group $RG \
    --name webserver$i \
    --vnet-name webservers-vnet \
    --subnet Applications \
    --nsg ERP-SERVERS-NSG \
    --image UbuntuLTS \
    --size Standard_DS1_v2 \
     --generate-ssh-keys \
    --admin-username azureuser \
    --custom-data cloud-init.yml \
    --no-wait \
    --admin-password 'C1sco123456$'
done

RG="tmp-20211121"
az group create --location westus3 --name $RG

az network vnet create \
--resource-group $RG \
--name webapp1-vnet \
--address-prefixes 10.0.0.0/16 \
--subnet-name webservers-snet \
--subnet-prefixes 10.0.1.0/24

az network vnet subnet create \
--resource-group $RG \
--vnet-name webapp1-vnet \
--name appservers-snet \
--address-prefixes 10.0.2.0/24

# create webserver nsg & cluster
az network nsg create --location westus3 --resource-group $RG --name webservers-nsg
az network nsg list --resource-group $RG -o table

for i in {1..3}
do az vm create \
    --resource-group $RG \
    --name webserver$i \
    --vnet-name webapp1-vnet \
    --subnet webservers-snet \
    --nsg webservers-nsg \
    --public-ip-sku Standard \
    --image UbuntuLTS \
    --size Standard_DS1_v2 \
    --generate-ssh-keys \
    --admin-username azureuser \
    --custom-data cloud-init.yml \
    --no-wait \
    --admin-password 'C1sco123456$'
done

az vm list \
    --resource-group $RG \
    --show-details \
    --query "[*].{Name:name, Provisioned:provisioningState, Power:powerState}" \
    --output table

az vm list \
    --resource-group $RG \
    --show-details \
    --query "[*].{Name:name, PrivateIP:privateIps, PublicIP:publicIps}" \
    --output table

# create appserver clusters
az network nsg create --location westus3 --resource-group $RG --name appservers-nsg
az network nsg list --resource-group $RG -o table

for i in {1..3}
do az vm create \
    --resource-group $RG \
    --name appserver$i \
    --vnet-name webapp1-vnet \
    --subnet appservers-snet \
    --nsg appservers-nsg \
    --public-ip-sku Standard \
    --image UbuntuLTS \
    --size Standard_DS1_v2 \
    --generate-ssh-keys \
    --admin-username azureuser \
    --custom-data cloud-init.yml \
    --no-wait \
    --admin-password 'C1sco123456$'
done

az vm list \
    --resource-group $RG \
    --show-details \
    --query "[*].{Name:name, Provisioned:provisioningState, Power:powerState}" \
    --output table

az vm list \
    --resource-group $RG \
    --show-details \
    --query "[*].{Name:name, PrivateIP:privateIps, PublicIP:publicIps}" \
    --output table

az vm list \
    --resource-group $RG \
    --show-details \
    --query "[*].{Name:name, Provisioned:provisioningState, Power:powerState, PrivateIP:privateIps, PublicIP:publicIps}" \
    --output table

# add ssh into webservers from poomlab
az network nsg rule create \
    --resource-group $RG \
    --nsg-name webservers-nsg \
    --name allow_ssh_poomlab \
    --direction Inbound \
    --priority 100 \
    --source-address-prefixes 76.184.207.222 \
    --source-port-ranges '*' \
    --destination-address-prefixes '*' \
    --destination-port-ranges 22 \
    --access Allow \
    --protocol Tcp \
    --description "Allow ssh from Poomlab to webservers"

# to remove a rule in nsg
az network nsg rule delete --resource-group $RG --nsg-name webservers-nsg --ids 100
