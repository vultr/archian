#!/bin/bash

function serverSetup {
    installOptional "Nvidia" "nvidia"
    installOptional "AMDGPU" "amdgpu"
    installOptional "Virtualization" "virt"
    installOptional "Docker" "docker"
    installOptional "LXD" "lxd"
    installOptional "Extras" "extras"
    installWine
}