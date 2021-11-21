# 2021.11.21
# short custom tutorial on Network Security Group / Application Security Group
# Scenarios:
# 3x web + 3x app
# web and app on separate subnet
# Findings:
# - NSG-at-subnet with ASG deny take effects even inside subnet while VM has no NSG

RG="tmp-20211121-1"
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

# create VMs without NSG

for i in {1..3}
do az vm create \
    --resource-group $RG \
    --name webserver$i \
    --vnet-name webapp1-vnet \
    --subnet webservers-snet \
    --nsg "" \
    --public-ip-sku Standard \
    --image UbuntuLTS \
    --size Standard_DS1_v2 \
    --generate-ssh-keys \
    --admin-username azureuser \
    --custom-data cloud-init.yml \
    --no-wait \
    --admin-password 'C1sco123456$'
done

for i in {1..3}
do az vm create \
    --resource-group $RG \
    --name appserver$i \
    --vnet-name webapp1-vnet \
    --subnet appservers-snet \
    --nsg "" \
    --public-ip-sku Standard \
    --image UbuntuLTS \
    --size Standard_DS1_v2 \
    --generate-ssh-keys \
    --admin-username azureuser \
    --custom-data cloud-init.yml \
    --no-wait \
    --admin-password 'C1sco123456$'
done

# list vms
az vm list \
    --resource-group $RG \
    --show-details \
    --query "[*].{Name:name, Provisioned:provisioningState, Power:powerState, PrivateIP:privateIps, PublicIP:publicIps}" \
    --output table

# create nsg for subnet
az network nsg create --location westus3 --resource-group $RG --name webservers-nsg
az network nsg create --location westus3 --resource-group $RG --name appservers-nsg
az network nsg create --location westus3 --resource-group $RG --name webapp1-nsg
az network nsg list --resource-group $RG -o table

# create asg
az network asg create \
--resource-group $RG \
--name webservers-asg

az network asg create \
--resource-group $RG \
--name appservers-asg

# associate web servers to asg
for i in {1..3}
do az network nic ip-config update \
--resource-group $RG \
--application-security-groups webservers-asg \
--name ipconfigwebserver${i} \
--nic-name webserver${i}VMNic \
--vnet-name webapp1-vnet \
--subnet webservers-snet
done

# associate app servers to asg
for i in {1..3}
do az network nic ip-config update \
--resource-group $RG \
--application-security-groups appservers-asg \
--name ipconfigappserver${i} \
--nic-name appserver${i}VMNic \
--vnet-name webapp1-vnet \
--subnet appservers-snet
done

# we should be able to ssh into web & app servers form poomlab
# and also see web can ssh to app server, let's prevent this

# add ssh deny rule to appservers-nsg
# from web-asg to app-asg denying ssh

== end ==
