#!/bin/bash

docker build -t uploadtest -f Dockerfile ../..
docker run -d uploadtest | xargs docker logs --follow
