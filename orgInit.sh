#!/bin/bash

#create scratch org
sfdx force:org:create -f config/project-scratch-def.json -a scratch --setdefaultusername -d 30

#install pckg for sample loginflows 
sfdx force:package:install --package 04t30000001DWL0AAO -w 20


sfdx force:source:push 

sfdx force:user:permset:assign -n Multi_Package_Installer_Admin

#sfdx force:data:tree:import --plan sfdx-out/plan.json

#Run Apex commands as needed
#sfdx force:apex:execute -f config/create-demo-data-setup.apex

sfdx force:org:open

