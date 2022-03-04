function searchPid {
        pid=$1
        batch=$(mktemp -t XXXXXX.gdb) && \
        cat >$batch<<EOF && gdb -p $pid --batch --command=$batch # 2>/dev/null | head -n 2 | tail -n 1
                    gcore /tmp/dump-$pid.core
                    quit
EOF 
        error=$?
        rm $batch 2>/dev/null
        if [ "$error" -ne 0 ] ; then
                false
        fi
}

function getPid {
        
	umount /proc/$pid
	date_creation=$(ps -eo lstart,cmd,pid | grep $pid |  grep -v grep | perl -pe 's/20(\d{2}).*$/20$1/')
    env_vars=$(cat /proc/$pid/environ | tr "\x00" "\n" | perl -pe 's/\x00/\n/g')
	date_detection=$(date +%A' '%d' '%B' '%H:%m:%S' '%Y | sed 's/\(.\)/\U\1/')
	port=$(ss -taupen 2>/dev/null | grep $pid | awk '{ print $5 }' | sed -E 's/^([0-9]{1,3}.){4}//')
    fichier_ouvert=$(ls -l /proc/$pid/fd | awk '{ print $11 }' | sed -e '/^$/d')
	librairies=$(cat /proc/$pid/maps | awk '{print $6}' | sort | uniq | perl -pe 's/^\n$//g' | grep '\.so')
	arguments=$(cat /proc/$pid/cmdline | perl -pe 's/\x00/ /g')


	echo -e "\n                       pour le PID $pid"


	echo -e "Date de création du processus : $date_creation\n"
	echo -e "Processus détécté le : $date_detection\n"

	echo -e "Liste des fichiers ouverts :"
	for fichier in $fichier_ouvert
	do
	        echo $fichier
	done
	echo -e "\n"

	if [ "$port" = "" ] ; then
		echo -e "port réseau : introuvable\n"
	else
		echo -e "port réseau : $port\n"
	fi

	echo -e "Liste des bibliothèques :"
	for lib in $librairies
        do
                echo $lib
        done
        echo -e "\n"

	echo -e "Liste des arguments :"
	for arg in $arguments
	do
		echo $arg
	done
        echo -e "\n"

	echo -e "Liste des variables d'environnement :"
	for var in $env_vars
	do
	        echo $var
	done
        echo -e "\n"

	echo -e "Mémoire du processus :"
	dumpPid $pid
}

PIDS=$(mount | grep -E "\/proc\/([0-9]{1,4})" | awk '{ print $3 }' | sed 's/\/proc\///')

for pid in $PIDS
do
        getPid $pid
done