#!/bin/bash

##########################################################
#
# Description : déploiment à la volée de conteneur docker
#
# Auteur : Lefsec
#
# Date : 09/01/2022
#
##########################################################

# si option --create
if [ "$1" == "--create" ];then

	#ternaire qui vérifie la valeur de $2(nombre de machine à créer)
	nb_machine=1
	[ "$2" != "" ] && nb_machine=$2
	
	#création des conteneurs
	echo""
	echo "Début de la création du/des conteneurs..."
	min=1
	max=0

	#récupération de l'id max
	idmax=`sudo docker ps -a --format '{{ .Names }}' | awk -F "-" -v user=$USER '$0 ~ user"-debian" {print $3}' | sort -r | head -1`
	
	min=$(($idmax + 1))
	max=$(($idmax + $nb_machine))

	for i in $(seq $min $max);do
		#sudo docker run -tid --name $USER-debian-$i debian:latest
		sudo docker run -tid --cap-add NET_ADMIN --cap-add SYS_ADMIN --publish-all=true -v /srv/data:/srv/html -v /sys/fs/cgroup:/sys/fs/cgroup:ro --name $USER-debian-$i -h $USER-debian-$i lefsec/debian9-systemd:latest
		sudo docker exec -ti $USER-debian-$i /bin/bash -c "useradd -m -p sa3tHJ3/KuYvI $USER"
		sudo docker exec -ti $USER-debian-$i /bin/bash -c "mkdir  ${HOME}/.ssh && chmod 700 ${HOME}/.ssh && chown $USER:$USER $HOME/.ssh"
		sudo docker cp $HOME/.ssh/id_rsa.pub $USER-debian-$i:$HOME/.ssh/authorized_keys
		sudo docker exec -ti $USER-debian-$i /bin/bash -c "chmod 600 ${HOME}/.ssh/authorized_keys && chown $USER:$USER $HOME/.ssh/authorized_keys"
		sudo docker exec -ti $USER-debian-$i /bin/bash -c "echo '$USER   ALL=(ALL) NOPASSWD: ALL'>>/etc/sudoers"
		sudo docker exec -ti $USER-debian-$i /bin/bash -c "service ssh start"
		echo "Conteneur $USER-debian-$i créé."
	done
	echo "Création de ${nb_machine} conteneurs."

# si option --drop
elif [ "$1" == "--drop" ];then

	echo""
	echo "Suppression des conteneurs..."
	sudo docker rm -f $(sudo docker ps -a | grep $USER-debian | awk '{print $1}')
	echo "Fin de la suppression."

# si option --infos
elif [ "$1" == "--infos" ];then

	echo""
	echo "Informations sur les conteneurs : "
	echo""
	for conteneur in $(sudo docker ps -a | grep $USER-debian | awk '{print $1}');do
		sudo docker inspect -f '  => {{ .Name }} - {{ .NetworkSettings.IPAddress }} ' $conteneur
	done
	echo""

# si option --start
elif [ "$1" == "--start" ];then

	echo""
	sudo docker start $(sudo docker ps -a | grep $USER-debian | awk '{print $1}')
	echo""

# si option --ansible
elif [ "$1" == "--ansible" ];then

	echo""
	echo "notre option est --ansible"
	echo""

# si aucune option affichage de l'aide
else

echo "

Options:
	--create : lancer des conteneurs
	--drop : supprimer les conteneurs créer par le script
	--infos : caractéristiques des conteneurs (ip, nom, user ...)
	--start : redémarrage des conteneurs
	--ansible : déploiement des arborescence ansible 

"
fi