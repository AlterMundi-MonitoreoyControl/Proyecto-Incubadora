#!/bin/bash
echo "obteniendo pull numero "$1
git status 
echo "verificar que no hay cambios si ves cambios presionar ctrl-c" 
read -n 1 -s
git fetch annie pull/$1/head:$1
git checkout $1
#$appfilecopy
echo "seguir procedimiento de pruebas para verificar que no se rompio nada"