# !bin/bash
input=$1
if [[ -z "$input" ]]; then
        echo "==========================================================================="
        echo "-------------------------How to start the script---------------------------"
        echo "==========================================================================="
        echo "./go-collections.sh pull = for pulling managed-schema"
        echo "./go-collections.sh push = for pushing managed-schema"
        echo "==========================================================================="
        exit
elif [ "$input" == "pull" ] || [ "$input" == "push" ]; then
        echo "==========================================================================="
        echo "------------------Please Wait Until The Process Finished-------------------"
        echo "==========================================================================="
else
        echo "==========================================================================="
        echo "-------------------------How to start the script---------------------------"
        echo "==========================================================================="
        echo "./go-collections.sh pull = for pulling managed-schema"
        echo "./go-collections.sh push = for pushing managed-schema"
        echo "==========================================================================="
        exit
fi


pwd=$(pwd)
DATE=$(date +%Y%m%d)
dirzk=$(jcmd | grep zookeeper-solr | awk '{print$3}')
port_zk=$(grep clientPort $dirzk | cut -d "=" -f 2)
ip=$(hostname -I | awk '{print$1}')
solr_dir=$(ps -ef | grep "Dsolr.solr.home" | grep -v grep  | awk '{print$49}' | awk 'NR==1{print$1}' | cut -d "=" -f 2)
solr_port=$(ps -ef | grep -v grep | grep "Dsolr.jetty.https.port=" | awk '{print$41}' | cut -d '=' -f 2 | awk 'NR==1{print$1}')

declare -a arr=(
`awk '1' $pwd/list.txt`
)

if [ "$input" == "pull" ]; then
        mkdir $pwd/managed-schema-new-$DATE > /dev/null 2>&1
        for collections in "${arr[@]}"
        do
                echo "-> Start pulling managed-schema from collection $collections"
                mkdir $pwd/managed-schema-new-$DATE/$collections > /dev/null 2>&1
                $solr_dir/bin/solr zk cp zk:/configs/$collections/managed-schema $pwd/managed-schema-new-$DATE/$collections/ -z $ip:$port_zk > /dev/null 2>&1
                echo "==========================================================================="
        done
                echo "-> Process pulling managed-schema finished!"
                echo "==========================================================================="
                echo "-> Your pulling data is on managed-schema-new-$DATE"
                echo "==========================================================================="
                echo "--------------------------Process $input Finished--------------------------"
                echo "==========================================================================="
elif [ "$input" == "push" ]; then
        mkdir managed-schema-backup-$DATE > /dev/null 2>&1
        for collections in "${arr[@]}"
        do
                echo "-> Starting push process.."
                echo "==========================================================================="
                echo "-> Backup managed-schema form collection $collections"
                echo "==========================================================================="
                mkdir $pwd/managed-schema-backup-$DATE/$collections-backup/ > /dev/null 2>&1
                $solr_dir/bin/solr zk cp zk:/configs/$collections/managed-schema $pwd/managed-schema-backup-$DATE/$collections-backup/ -z $ip:$port_zk > /dev/null 2>&1
                echo "-> Start pushing managed-schema-new-$DATE to collection $collections"
                echo "==========================================================================="
                $solr_dir/bin/solr zk cp $pwd/managed-schema-new-$DATE/$collections/managed-schema zk:/configs/$collections/managed-schema -z $ip:$port_zk > /dev/null 2>&1
                echo "-> Start to reload colletion for collection $collections"
                echo "==========================================================================="
                curl --user user:passowrd "http://localhost:$solr_port/solr/admin/collections?action=RELOAD&name=$collections"
                echo "==========================================================================="
        done
                echo "-> Process pushing managed-schema finished! please check it!"
                echo "==========================================================================="
                echo "-> Your backup managed-schema is on managed-schema-backup-$DATE"
                echo "==========================================================================="
                echo "--------------------------Process $input Finished--------------------------"
                echo "==========================================================================="
fi
