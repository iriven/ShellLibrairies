#!/usr/bin/env bash
# Header_start
#################################################################################
#										#
#   Bibliotheque de functions utiles à la creation de scripts et applications	#
#   shell Unix									#
# ----------------------------------------------------------------------------- #
#   Author: Alfred TCHONDJO - Iriven France					#
#   Date: 2016-02-13								#
# ----------------------------------------------------------------------------- #
#   Revisions									#
#										#
#   G1R0C0 : 	Creation du script le 13/02/2016 (AT)				#
# -----------------------------------------------------------------------------	#
#   Function List				                                #										#							#   arrayDiff  arrayIntersect  arrayKeys  arrayMap  arrayMerge  arraySize	#
#   explode  functionExists  getMacAddr	getUid	inArray  IndexOf  isAlpha	#
#   isAlphaNum	  isBoolean  isNumeric	isRoot  isSet  ltrim  pregMatch  rtrim  #
#   source  strCapitalize  strContains  strLength strPosition strRemove	        #
#   strRemove  strLowerCase  strUpperCase  subString  trim  ucfirst userExists  #
#################################################################################
# Header_end
# set -x
#-------------------------------------------------------------------
# verifie l'existence ou non d'une function
# @params: $function  , nom de la function à tester
# @return: Boolean
#-------------------------------------------------------------------
if ! type -t functionExists | grep -q '^function$' 2>/dev/null; then
	PATH=/bin:/sbin:/usr/bin:/usr/sbin:$PATH
	function functionExists() {
		[ $# -ne 1 -o -z "$1" ] && printf "Usage: ${0} [string FUNCTNAME]" && exit 1
		type -t "$1" | grep -q '^function$' 2>/dev/null && return 0 ||return 1
	}
fi
#-------------------------------------------------------------------
# retourne les elements d'un tableau B absents du tableau A 
# @params: $arrayA  , premier tableau
# @params: $arrayB  , second tableau
# @echo: (array) B - A
#-------------------------------------------------------------------
if ! functionExists "arrayDiff" ; then
	function arrayDiff(){
		[ $# -ne 2 ] && printf "Usage: ${0} [array ARRAY1] [array ARRAY2]" && exit 1
		local array1=("$1")  array2=("$2")
		local output=($(comm -13 <(printf '%s\n' "${array1[@]}" | LC_ALL=C sort) <(printf '%s\n' "${array2[@]}" | LC_ALL=C sort)))
		echo "$output[@]"
	}
fi
#-------------------------------------------------------------------
# retourne les elements d'un tableau A aussi presents dans B 
# @params: $arrayA  , premier tableau
# @params: $arrayB  , second tableau
# @echo: (array) A AND B
#-------------------------------------------------------------------
if ! functionExists "arrayIntersect" ; then
	function arrayIntersect(){
		[ $# -ne 2 ] && printf "Usage: ${0} [array ARRAY1] [array ARRAY2]" && exit 1
		local array1=("$1")  array2=("$2")
		local output=($(comm -12 <(printf '%s\n' "${array1[@]}" | LC_ALL=C sort) <(printf '%s\n' "${array2[@]}" | LC_ALL=C sort)))
		echo "$output[@]"
	}
fi
#-------------------------------------------------------------------
# Liste les index d'un tableau 
# @params: $array  , tableau cible
# @echo: string
#-------------------------------------------------------------------
if ! functionExists "arrayKeys" ; then
	function arrayKeys(){
		[ $# -ne 1 -o -z "$1" ] && printf "Usage: ${0} [array ARRAY]" && exit 1
		echo "${!${1}[@]}"
	}
fi
#-------------------------------------------------------------------
# applique une fonction utilisateur à chaque element d'un tableau
# @params: $callback  , nom de la fonction de rappel
# @params: $array  , tableau cible
# @echo: array
#-------------------------------------------------------------------
if ! functionExists "arrayMap" ; then
	function arrayMap (){
		[ $# -ne 2 ] && printf "Usage: ${0} [function CALLBACK] [array ARRAY]" && exit 1
		local callback="$1" arr=("$2") output n=0 
		! functionExists "${callback}" && echo "Error: unknown callback function: ${callback}" && exit 1
		while [ $n -lt ${#arr[@]} ]
		do
		output["$n"]=`echo $($callback $arr["$n"])`
		let n+=1;
		done
		  echo "$output[@]"
	}
fi
#-------------------------------------------------------------------
# fusionne plusieurs tableaux en un seul
# @params: $array1 $array2 ... $arrayN , les tableaux cibles
# @echo: Array
#-------------------------------------------------------------------
if ! functionExists "arrayMerge" ; then
	function arrayMerge(){
		[ $# -lt 2 ] && printf "Usage: ${0} [array ARRAY1] [array ARRAY2] ...[array ARRAYN]" && exit 1
		local input=("$@")
		local output=`echo "${input[@]}" | sort -u`
		echo "$output[@]"
	}
fi
#-------------------------------------------------------------------
# Retourne le nombre d'elements d'un tableau 
# @params: $array  , tableau cible
# @echo: number
#-------------------------------------------------------------------
if ! functionExists "arraySize" ; then
	function arraySize(){
	[ $# -ne 1 -o -z "$1" ] && printf "Usage: ${0} [array ARRAY]" && exit 1
		echo "${#${1}[@]}"
	}
fi
#-------------------------------------------------------------------
# Transforme une chaine de caracteres en tableau suivant 
# @params: $string  , chaine à convertir
# @params: $delimiter  , (optionnel) delimiteur
# @echo: array
#-------------------------------------------------------------------
if ! functionExists "explode" ; then
	function explode(){
		[ $# -ne 2 -o -z "$1" ] && printf "Usage: ${0} [string STRING] [char SEPARATOR]" && exit 1
		local output string="$1" IFS="${2:- }"
		read -ra output <<< "${string}"
		echo "${output[@]}"
	}
fi
#-------------------------------------------------------------------
# recupere l'adresse mac d'une interface reseau
# @params: $iface  , nom de l'interface reseau cible
# @echo: Mac Adress
#-------------------------------------------------------------------
if ! functionExists "getMacAddr" ; then
	function getMacAddr (){
		[ $# -ne 1 -o -z "$1" ] && printf "Usage: ${0} [string INTERFACE]" && exit 1
		local iface="$1"
		if [ -f "/sys/class/net/${iface}/address" ]; then
			awk '{ print toupper($0) }' < "/sys/class/net/${iface}/address"
		elif [ -d "/sys/class/net/${iface}" ]; then
			LC_ALL= LANG= ip -o link show "${iface}" 2>/dev/null | \
				awk '{ print toupper(gensub(/.*link\/[^ ]* ([[:alnum:]:]*).*/,"\\1", 1)); }'
		fi
	}
fi
#-------------------------------------------------------------------
# retourne l'ID d'un user donné. si appelé sans argument,
# retourne l'ID du user actuel
# @params: $username  , nom de l'utilisateur cible
# @echo: Number
#-------------------------------------------------------------------
if ! functionExists "getUid" ; then
	function getUid (){
		[ $# -gt 1 ] && printf "Usage: ${0} [string USERNAME]" && exit 1
		local username="${1-`who | awk '{ print $1 }' | tail -1`}"
		#[ -z "${username}" ] && username=$(who | awk '{ print $1 }' | tail -1)
		! userExists "${username}" && printf "Error: User \"${username}\" not found on this server" && exit 1
		echo $(id -u "${username}")

	}
fi
#-------------------------------------------------------------------
# verifie si une chaine est un element d'un tableau
# @params: $string  , chaine à rechercher
# @params: $array  , tableau cible
# @params: $delimiter ,(optionnel) separateur des elements du tableau
# @return: Boolean
#-------------------------------------------------------------------
if ! functionExists "inArray" ; then
	function inArray(){
		[ $# -ne 2 -a $# -ne 3 ] && printf "Usage: ${0} [string STRING] [array ARRAY] [(optional) char SEPARATOR]" && exit 1
		local string="$1" inputArray IFS="${3:- }"
		read -ra inputArray <<< "$2"
		case "${IFS}${inputArray[*]}${IFS}" in
		*"${IFS}${string}${IFS}"*) return 0;;
		*) return 1 ;;
		esac
	}
fi
#-------------------------------------------------------------------
# retourne l'index d'un element du tableau
# @params: $string  , la valeur
# @params: $array  , tableau cible
# @echo: string|Number
#-------------------------------------------------------------------
if ! functionExists "IndexOf" ; then
	function IndexOf(){
	[ $# -ne 2 -o -z "$1" ] && printf "Usage: ${0}[string STRING] [array ARRAY] " && exit 1
		local value="$1" ARRAY=("$2") index=0;
		! inArray "${value}" "${ARRAY[@]}" && printf "${value} not found in the target array " && exit 1
		while [ "$index" -lt "${#ARRAY[@]}" ]; do
			[ "${ARRAY[$index]}" = "$value" ] && echo "$index" && return 0;
			let index+=1; 
		done
	}
fi
#-------------------------------------------------------------------
# verifie si une variable ne contient que des caracteres alphabetiques 
# @params: $string  , chaine à tester
# @return: Boolean
#-------------------------------------------------------------------
if ! functionExists "isAlpha" ; then
	function isAlpha() {  
	  [ $# -ne 1 -o -z "$1" ] && printf "Usage: ${0} [string STRING]" && exit 1
	  local input="$1"
	  case "$input" in
	  *[!a-zA-Z]*|'') return 1;;
	  *) return 0;;
	  esac          
	}
fi
#-------------------------------------------------------------------
# teste si une variable ne contient que des caracteres alphanumeriques 
# @params: $string  , chaine à tester
# @return: Boolean
#-------------------------------------------------------------------
if ! functionExists "isAlphaNum" ; then
	function isAlphaNum() {  
	  [ $# -ne 1 -o -z "$1" ] && printf "Usage: ${0} [string STRING]" && exit 1
	  local input="$1"
	  case "$input" in
	  *[!a-zA-Z0-9]*|'') return 1;;
	  *) return 0;;
	  esac          
	}
fi
#-------------------------------------------------------------------
# teste si une variable est de type booléen 
# @params: $string  , chaine à tester
# @return: Boolean
#-------------------------------------------------------------------
if ! functionExists "isBoolean" ; then
	function isBoolean() {  
	  [ $# -ne 1 -o -z "$1" ] && printf "Usage: ${0} [string STRING]" && exit 1
	  local input=$(echo "$1"|tr '[A-Z]' '[a-z]')
	  case "$input" in
	  '0'|'1'|'true'|'false') return 0;;
	  *) return 1;;
	  esac          
	}
fi
#-------------------------------------------------------------------
# teste si une variable est de type numerique 
# @params: $string  , chaine à tester
# @return: Boolean
#-------------------------------------------------------------------
if ! functionExists "isNumeric" ; then
	function isNumeric() {  
	  [ $# -ne 1 -o -z "$1" ] && printf "Usage: ${0} [string STRING]" && exit 1
	  local input="$1"
	  case "$input" in
	  *[!0-9,]*|*[!0-9]*|,*|'') return 1;;
	  *) return 0;;
	  esac          
	}
fi
#-------------------------------------------------------------------
# indique si un user est admin du systeme
# @params: $username  , nom de l'utilisateur cible
# @return: Boolean
#-------------------------------------------------------------------
if ! functionExists "isRoot" ; then
	function isRoot (){
		[ $# -gt 1 ] && printf "Usage: ${0} [string USERNAME]" && exit 1
		local username="${1-`who | awk '{ print $1 }' | tail -1`}"
		! userExists "${username}" && printf "Error: User \"${username}\" not found on this server" && exit 1
		[ $(getUid "${username}") -eq 0 ] && return 0 || return 1
	}
fi
#-------------------------------------------------------------------
# verifier si une variable est definie  
# @params: $varname  , nom de la variable à tester
# @return: Boolean
#-------------------------------------------------------------------
if ! functionExists "isSet" ; then
	function isSet() {
		[ $# -ne 1 -o -z "$1" ] && printf "Usage: ${0} [string VARNAME]" && exit 1
		 local v="$1"
		[[ ! ${!v} && ${!v-_} ]] && return 1 || return 0
	}
fi
#-------------------------------------------------------------------
# supprime un caractere au debut d'une chaine
# @params: $string  , la chaine cible
# @echo: String
#-------------------------------------------------------------------
if ! functionExists "ltrim" ; then
	function ltrim(){
        [ $# -ne 1 -a $# -ne 2 ] && printf "Usage: ${0} [string STRING] [(optional) string NEEDLE]" && exit 1
		local input="${1#*( )}"
		[ $# -eq 2 -a ! -z "$2"  ] && echo "${input##${2}}" || echo "$input"
    }
fi
#-------------------------------------------------------------------
# teste si une chaine verifie une expression régulière ou non
# @params: $string  , chaine à tester
# @params: $regex  , masque ou expression reguliere
# @return: Boolean
#-------------------------------------------------------------------
if ! functionExists "pregMatch" ; then
	function pregMatch(){
		[ $# -ne 2 -o -z "$1" ] && printf "Usage: ${0} [string STRING] [string REGEXP]" && exit 1
		local input="$1" regex="$2"
		expr match "$input" "$regex" && return 0 || return 1
	}
fi
#-------------------------------------------------------------------
# supprime un caractere donné à la fin d'une chaine 
# @params: $string  , la chaine cible
# @echo: String
#-------------------------------------------------------------------
if ! functionExists "rtrim" ; then
	function rtrim(){
        [ $# -ne 1 -a $# -ne 2 ] && printf "Usage: ${0} [string STRING] [(optional) string NEEDLE]" && exit 1
		local input="${1#*( )}"
		[ $# -eq 2 -a ! -z "$2"  ] && echo "${input%%${2}}" || echo "$input"
    }
fi
#-------------------------------------------------------------------
# Importe un fichier de configuration ou une bibliotheque de fonctions
# dans un script
# @params: $string  , chemin du fichier à importer
#-------------------------------------------------------------------
if ! functionExists "source" ; then
	function source(){
		[ $# -ne 1 -o -z "$1" ] && printf "Usage: ${0} [string FILEPATH]" && exit 1
		[ ! -f "$1" ] && printf "ERROR: Unable to load ${1}" && exit 1
		local filepath="$1"
		. "${filepath}" && return 0
	}
fi
#-------------------------------------------------------------------
# Dans une chaine, transforme les premiers lettres de chaque mots
# en majuscules
# @params: $string  , chaine à tester
# @echo: String
#-------------------------------------------------------------------
if ! functionExists "strCapitalize" ; then
	function strCapitalize(){
		[ $# -ne 1 -o -z "$1" ] && printf "Usage: ${0} [string STRING]" && exit 1
		local input="$1" 
		echo "${input}" | awk '{for(i=1;i<=NF;i++)sub(/./,toupper(substr($i,1,1)),$i)}1'
	}
fi
#-------------------------------------------------------------------
# teste si une chaine contient une autre
# @params: $string  , chaine à tester
# @params: $needle  , masque ou expression reguliere
# @return: Boolean
#-------------------------------------------------------------------
if ! functionExists "strContains" ; then
	function strContains(){
		[ $# -ne 2 -o -z "$1" ] && printf "Usage: ${0} [string STRING] [string NEEDLE]" && exit 1
		local input="$1" needle="$2"
		local check = $(echo "${input}" | grep "${needle}" 1> /dev/null )
		[ ! -z "${check}" ] && return 0 || return 1
	}
fi
#-------------------------------------------------------------------
# Affiche le taille d'une chaine de caracteres donnés
# @params: $string  , la chaine cible
# @echo: Number
#-------------------------------------------------------------------
if ! functionExists "strLength" ; then
	function strLength(){
		[ $# -ne 1 ] && printf "Usage: ${0} [string STRING]" && exit 1
		local inputText="$1"
		echo $(expr length ${inputText})
	}
fi
#-------------------------------------------------------------------
# transforme les caracteres d'une chaine en minuscules
# @params: $string  , la chaine à transformer
# @echo: String
#-------------------------------------------------------------------
if ! functionExists "strLowerCase" ; then
	function strLowerCase () { 
		[ $# -ne 1 -o -z "$1" ] && printf "Usage: ${0} [string STRING]" && exit 1
		local input="$1"
		echo "${input}" | tr 'A-Z' 'a-z'
	}
fi
#-------------------------------------------------------------------
# retourne la position de la première occurence d'une chaine dans
# un texte 
# @params: $search  , la chaine à rechercher
# @params: $string  , la chaine à cible
# @echo: Number
#-------------------------------------------------------------------
if ! functionExists "strPosition" ; then
	function strPosition(){
		[ $# -ne 2 -o -z "$2" ] && printf "Usage: ${0} [string SEARCH] [string STRING]" && exit 1
		local search="$1" inputText="$2"
		local position=$(expr index ${inputText} ${search})
		echo "${position}"
		[ $position -ne 0 ] &&  return 0 || return 1
	}
fi
#-------------------------------------------------------------------
# supprime toutes les occurences d'une chaine de caractere dans un texte 
# @params: $search  , la chaine à supprimer
# @params: $string  , la chaine à cible
# @echo: String
#-------------------------------------------------------------------
if ! functionExists "strRemove" ; then
	function strRemove(){
		[ $# -ne 2 -o -z "$2" ] && printf "Usage: ${0} [string SEARCH] [string STRING]" && exit 1
		local search="$1" inputText="$2"
		echo $(strReplace "${search}" "" "${inputText}")
	}
fi
#-------------------------------------------------------------------
# remplace dans une variable de type chaine toutes les occurences
# d'un mot/caractere par un autre
# @params: $search  , la chaine à rechercher
# @params: $replace  , la valeur de remplacement
# @params: $string  , la chaine à transformer
# @echo: String
#-------------------------------------------------------------------
if ! functionExists "strReplace" ; then
	function strReplace(){
		[ $# -ne 3 ] && printf "Usage: ${0}  [string SEARCH] [string REPLACE] [string STRING]" && exit 1
		local search="$1" newValue="$2" inputText="$3"
		echo "${inputText}" | sed -e "s/${search}/${newValue}/g"
	}
fi
#-------------------------------------------------------------------
# transforme les caracteres d'une chaine en majuscules
# @params: $string  , la chaine à transformer
# @echo: String
#-------------------------------------------------------------------
if ! functionExists "strUpperCase" ; then
	function strUpperCase () { 
		[ $# -ne 1 -o -z "$1" ] && printf "Usage: ${0} [string STRING]" && exit 1
		local input="$1"
		echo "${input}" | tr 'a-z' 'A-Z'
	}
fi
#-------------------------------------------------------------------
# extrait une sous_chaine d'une chaine de caracteres
# @params: $string  , la chaine cible
# @params: $position  , position de depart
# @params: $length  , longueur de la chaine à extraire
# @echo: String
#-------------------------------------------------------------------
if ! functionExists "subString" ; then
	function subString(){
		[ $# -ne 2 -a $# -ne 3 ] && printf "Usage: ${0} [string STRING] [integer POSITION] [integer LENGTH]" && exit 1
		local input="$1" offset="$2" 
		[ $# -ne 3 ] && local length=$(strLength "${input}") || local length="$3"
		echo $(expr substr "${input}" "${offset}" "${length}")
	}
fi
#-------------------------------------------------------------------
# supprime un caractrere donné au debut et à la	fin  d'une chaine
# @params: $string  , la chaine à transformer
# @echo: String
#-------------------------------------------------------------------
if ! functionExists "trim" ; then
	function trim(){
		[ $# -ne 1 -a $# -ne 2 ] && printf "Usage: ${0} [string STRING] [(optional) string NEEDLE]" && exit 1
		local output=$(ltrim "$1")
		if [ $# - eq 2 ]; then
		local output=$(ltrim "$output" "$2")
		local output=$(rtrim "$output" "$2")
		fi
		echo "${output}"
	}
fi
#-------------------------------------------------------------------
# transforme la premiere lettre d'une chaine en majuscules	
# @params: $string  , la chaine à transformer
# @echo: String
#-------------------------------------------------------------------
if ! functionExists "ucfirst" ; then
	function ucfirst (){                            
		[ $# -ne 1 -o -z "$1" ] && printf "Usage: ${0} [string STRING]" && exit 1
		local input=`echo "${@}" | tr 'A-Z' 'a-z'`
		local rest=${input:1} firstchar=`echo ${input:0:1} | tr 'a-z' 'A-Z'`
		echo "${firstchar}${rest}"
	}
fi
#-------------------------------------------------------------------
# verifie l'existence ou non d'un user sur le systeme
# @params: $username  , nom de l'utilisateur cible
# @return: Boolean
#-------------------------------------------------------------------
if ! functionExists "userExists" ; then
	function userExists (){
		[ $# -ne 1 -o -z "$1" ] && printf "Usage: ${0} [string USERNAME]" && exit 1
		local username="${1}"
		grep "^${username}:" /etc/passwd > /dev/null 2>&1 && return 0 || return 1
	}
fi
#-------------------------------------------------------------------
# decode une chaine au format url
# @params: $string  , url encodée
# @return: String
#-------------------------------------------------------------------
if ! functionExists "urDecode" ; then
	function urDecode() {
		[ $# -ne 1 -o -z "$1" ] && printf "Usage: ${0} [string URL]" && exit 1
		local url="$1"
		echo "${url}" | sed "s/%0A/\n/g;s/%22/\"/g;s/%28/\(/g;s/%29/\)/g;s/%26/\&/g;s/%3D/\=/g"
	}
fi
#-------------------------------------------------------------------
# encode une chaine au format url
# @params: $string  , url à encoder
# @return: String
#-------------------------------------------------------------------
if ! functionExists "urlEncode" ; then
	function urlencode() {
		[ $# -ne 1 -o -z "$1" ] && printf "Usage: ${0} [string URL]" && exit 1
		local url="$1"
		echo "${url}" | tr '\n' "^" | sed -e 's/%/%25/g;s/ /%20/g;s/!/%21/g;s/"/%22/g;s/#/%23/g;s/\$/%24/g;s/\&/%26/g;s/=/%3D/g;s/'\''/%27/g;s/(/%28/g;s/)/%29/g' -e "s/\^$//;s/\^/%0A/g"
	}
fi
