#!/bin/sh


echo "checking response code for 60 seconds"

for i in $(seq 0 1 60)
  do code=$(curl -s -o /dev/null -I -w "%{http_code}" $DOCKER_HOST:8081)
     if [ "$code" = "200" ]
     then 
       echo "Good, response code is" $code
       exit 0	     
     else 
       echo "Bad, response code is " $code
       sleep 1
     fi
done
echo "unable to reach localhost on 8081 in 60s"
exit 1




#i=20
#while $(seq 5 10 10)
#  do 
#    if [ "$code" = "300" ]; then
#     echo "Good, response code is" $code
#    else
#      echo "Bad, response code is " $code
#    fi
# done
