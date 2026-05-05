# Build custom VM images with Azure Image Builder

This repository contains sample code for building custom VM images on Azure. You might need this to create VMs that have been pre-configured and come with pre-installed software for whatever purpose.

The image template is configured with a base image to start our image building process from, customisation scripts that install software and modify the image, and distribution method(s) once the image is built.

# Samples

| Sample name   | Description   |
|---------------|---------------|
| [Software from public repositories](./software-from-public) | This sample demonstrates how to create an Azure Image Builder that installs publicly accessible software. |
| [Software from Azure Storage](./software-from-azure-storage) | This sample demonstrates how to create an Azure Image Builder that downloads and installs software from a private Azure Storage account using a managed identity. |