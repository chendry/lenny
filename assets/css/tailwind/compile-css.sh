#!/bin/bash

docker run --rm -it --volume $(realpath ../../..):/lenny lenny-tailwind
