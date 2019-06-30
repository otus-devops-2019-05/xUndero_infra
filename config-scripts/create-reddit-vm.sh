#!/bin/bash
gcloud compute instances create reddit-app2 --image-family reddit-full --machine-type=g1-small --tags puma-server --restart-on-failure
