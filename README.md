# dspace-dev-docker

DSpace instant development environment using Docker Compose

# What?

This is currently a proof of concept. It aims at offering an easy to install, productivity focused, DSpace development 
environment.

# How?

This project runs on Docker-compose, setting up two containers: one for DSpace development environment and one for Postgres.
The development container should include not only all DSpace's prerequisites but also some tweaks to get faster builds,
deployments and better code hot-swapping. Eventually this should also include a preconfigured IDE, accessible using
X11 forwarding to start running and debugging the project. 

# Why?

I believe that setting up a productive development environment for DSpace is non-trivial:
The build system is 'OK' in the sense that it gets the job done, but it doen't feel right for development. A lot of files get
copied around, compressed, decompressed and compressed again.

Maven itself is not prone to doing things incrementally out of the box. IDEs can help but it steel feels hard to get an
acceptable configuration that avoids full rebuilds. To top that, having the user running ant tasks after maven to get DSpace 
running ensures that your IDE won't understand the full process.

Anyway, it seems that there are lots of things that can be done to hasten the code -> build -> run -> test cycle but it's
kind of messy to do it on your workstation. Having a container that keeps all this customizations in isolation should
encourage experimenting with further tweaks.
