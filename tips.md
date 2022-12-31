# How I installed dotnet

## apt-get hanging
After spending way too long trying to figure out why `sudo apt-get update` was
hanging, I tried updating wsl with `wsl --update` from parent machine. I was
then able to use apt-get from inside wsl.

## Install dotnet
To install dotnet, I downloaded the tarball from the microsoft download page and
followed the instructions there after moving the file to my wsl home directory.
