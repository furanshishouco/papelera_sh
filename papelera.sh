#!/bin/bash

#######      Ejercicio:  Papelera en bash      #######
#       Autor: Francisco Javier Molina Mendoza       #
###     Asignatura:  Sistemas Informáticos MyM       #
#            Fecha finalización: 28/02/08           #
#          Host: Linux FRN-DEB 2.6.22-3-686    #####  

#Impresión de la ayuda
function ayuda()
{
	echo "Modo de uso"
	echo -e "\tpapelera.sh --borrar archivo1 [archivo2 ...]"
	echo -e "\tpapelera.sh --restaurar archivo1 [archivo2 ...]"
	echo -e "\tpapelera.sh --vaciar"
	echo -e "\tpapelera.sh --listar"
}

#Busca si el elemento está repetido en el log y lo elimina
function repetidos()
{
	local a=$(grep "$fnom:$fdir" $dir/log | wc -l)
	if [ $a -eq 1 ]; then
		local lin=$(grep -n "$fnom:$fdir" $dir/log | cut -d : -f 1)
		local fic=$(grep -n "$fnom:$fdir" $dir/log | cut -d : -f 4)
		rm $dir/$fic
		sed "$lin d" $dir/log > $dir/log2
		mv $dir/log2 $dir/log
	fi
}

#Variables globales
dir=/var/papelera
pos=$(pwd)
## Fichero donde almacenamos la lista de ficheros borrados
[ -a $dir/log ] || touch $dir/log
## Fichero con un número para evitar nombres duplicados en la papelera
[ -a $dir/tam ] || echo 0 > $dir/tam

#Comprobación de argumentos de entrada
[ $# -lt 1 ] && { echo -e "No se ha especificado una operación\nPruebe \"papelera.sh --help\" para más información"; \
		  exit 1; }
#Comprobación de las opciones
#	Impresión de ayuda
[ $# -eq 1 ] && [ $1 == "--help" ] && { ayuda; exit 0; }

#	Borrar archivos
if [ $# -gt 1 ] && [ $1 == "--borrar" ]; then
	shift
	while [ $# -gt 0 ]
	do
		fnom=$(basename $1)
		fdir=$(dirname $1)
		repetidos
		##Comprobamos que existe
		if [ -a $1 ]; then
			##Variables diferenciadoras
			tam=$(cat /var/papelera/tam)
			(( tam++ ))
			fec=$(date +%H%M%S-%d%m%y)
			##Si es un directorio
			cd $fdir
			if [ -d $1 ]; then
				if [ -w $1 ]; then
					#lo empaquetamos y lo guardamos en la papelera
					tar cf $dir/$fnom.$fec-$tam $fnom
					rm -rf $fnom
					echo "$fnom:$(pwd):$fnom.$fec-$tam:$fec:dir:$tam" >> $dir/log
				else
					echo "No tiene permisos para borrar el directorio $1"
				fi
			fi
			##Si es un fichero
			if [ -f $1 ]; then
				if [ -w $1 ]; then
					#lo movemos a la papelera con otro nombre
					mv $fnom $dir/$fnom.$fec-$tam
					echo "$fnom:$(pwd):$fnom.$fec-$tam:$fec:arc:$tam" >> $dir/log
				else
					echo "No tiene permisos para borrar el archivo $1"
				fi
			fi
		else
			echo "El archivo o directorio $1 no existe"
		fi
		shift
		echo $tam > $dir/tam
		cd $pos
	done
	exit 0
fi

#	Vaciar la papelera
##Borramos todo el contenido de la papelera
[ $# -eq 1 ] && [ $1 == "--vaciar" ] && { rm -rf $dir/*; exit 0; }

#	Restaurar archivos de la papelera
if [ $# -gt 1 ] && [ $1 == "--restaurar" ]; then
	shift
	while [ $# -gt 0 ]
	do
		IFS=:
		lin=1
		##Leemos el log linea a linea
		exec 3<$dir/log
		while read -u3 nom origen nnom fec tipo tam
		do
			cd $dir
			nombre=$origen/$nom
			#y si el nombre coincide con la entrada
			if [ $nombre == $1 ]; then
				[ -e $1 ] && { echo "Ya existe el fichero destino $nombre"; continue; }
				#lo restauramos
				[ $tipo == "arc" ] && { mv $nnom $nombre; } || \
						      { cd $origen; tar xf $dir/$nnom; rm $dir/$nnom; }
				#y borramos la linea del log
				sed "$lin d" $dir/log > $dir/log2
				mv $dir/log2 $dir/log
			fi
			(( lin++ ))
		done
		shift
	done
	exit 0
fi

#	Mostrar los archivos en la papelera
if [ $# -eq 1 ] && [ $1 == "--listar" ]; then
	[ -s $dir/log ] || { echo "La papelera está vacía"; exit 0; }
	IFS=:
	##Leemos el fichero log linea a linea
	exec 3<$dir/log
	while read -u3 nom origen nnom fec tipo tam
	do
		hora=$(echo $fec | cut -d - -f 1)
		dia=$(echo $fec | cut -d - -f 2 )
		#y mostramos un mensaje con el tipo, el nombre y la fecha de borrado del archivo
		[ $tipo == "arc" ] && { echo -ne "Archivo:\t"; } || { echo -ne "Directorio:\t"; }
		echo "$origen/$nom; borrado el $dia a las $hora"
	done
	exit 0
fi
