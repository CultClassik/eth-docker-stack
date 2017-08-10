#!/bin/bash
# Chris Diehl

myhost=`uname -n`

# kill all miner containers
nvminers=`docker ps -aq --filter "name=nvminer"`
for m in "${nvminers[@]}";
do
  nvidia-docker rm --force $m;
done

# GPU Core Speed adjustment
gpucoreoc="-150"

# GPU VRAM speed adjustment
gpumemoc="1650"

# GPU Power Level Limit
gpupl="75"

# GPU Fan Speed
gpufanspd="60"

# Enable power limit for GPUs and set the value
 nvidia-smi -pm ENABLED &&\
  nvidia-smi -pl $gpupl

# start X session to enable gpu access
#killall X
#X :1 &
# Find all Nvidia GPUs
gpu_count=0
IFS=')'
gpus=($(nvidia-smi -L))
for x in "${gpus[@]}"; do gpu_count=$(( $gpu_count + 1 )); done
count=$((gpu_count))
echo "Found $count NVidia GPUs"

# set fan speed and overclock settings and start a miner container for each
for ((i=0; i < $count; ++i))
do
  nvidia-settings -a "[gpu:$i]/GPUGraphicsClockOffset[3]=$gpucoreoc" \
    -a "[gpu:$i]/GPUMemoryTransferRateOffset[3]=$gpumemoc" \
    -a "[gpu:$i]/GPUFanControlState=1" \
    -a "[fan:$i]/GPUTargetFanSpeed=$gpufanspd" \
    -a "[gpu:$i]/GPUPowerMizerMode=1"
  NV_GPU=$i dockerHost=$myhost nvidia-docker run -d --name=nvminer$1 cultclassik/nvworker
done

myhost=`uname -n` &&\
NV_GPU=0 dockerHost=$myhost nvidia-docker run -d --name=nvminer$1 cultclassik/nvworker

dockerHost=$myhost nvidia-docker run -d --name=nvminer$1 cultclassik/nvworker
