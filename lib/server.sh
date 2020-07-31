#!/bin/bash

function serverSetup {
    installOptional "Nvidia" "nvidia"
    installOptional "AMDGPU" "amdgpu"
    installOptional "Virtualization" "virt"
    installWine
}