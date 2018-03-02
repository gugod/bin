#!/bin/bash

docker rm $(docker ps -qa)
docker images --no-trunc | awk '{print $3}' | xargs -n1 docker rmi
