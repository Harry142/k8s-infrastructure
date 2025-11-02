#!/bin/bash

# Create VMs
multipass launch --name k8s-master --cpus 2 --memory 4G --disk 20G 22.04
multipass launch --name k8s-worker1 --cpus 2 --memory 2G --disk 20G 22.04
multipass launch --name k8s-worker2 --cpus 2 --memory 2G --disk 20G 22.04

echo "VMs created successfully!"
