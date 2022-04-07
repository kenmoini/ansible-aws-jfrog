# Jfrog pre-configuration 

## Create Docker repo endpoint 
`Repositories->Repositories`  
Click on `+ Add repositories` Local Repository   
![20220315095728](https://i.imgur.com/PJyCiab.png)

Click on Docker
![20220315095838](https://i.imgur.com/aqJ9Rty.png)

Create `ocp4` Repository Key
![20220315100429](https://i.imgur.com/ISVqvBy.png)
> uncheck `Block pushing of image manifest v2 schema 1`	
![20220315102737](https://i.imgur.com/zzaoqGc.png)

## Create libs-release-local for isos
`Repositories->Repositories`  
Click on `+ Add repositories` Local Repository   
![20220315095728](https://i.imgur.com/PJyCiab.png)

Click on Generic
![20220315100218](https://i.imgur.com/CgW7JhR.png)

Create ` libs-release-local` Repository Key
![20220315102442](https://i.imgur.com/5PeYN0d.png)

# Change repository storage limit 
`JFrog Container Registry` -> `Settings`
Change `* File Upload In UI Max Size (MB)` to 1000 MB
![20220316104253](https://i.imgur.com/hAbyGaO.png)