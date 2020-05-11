function pause {
    ( [ -z "$1" ] && echo "Press any key to continue..." ) || echo $1
    read -n1
}