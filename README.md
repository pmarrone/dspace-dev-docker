# dspace-dev-docker

DSpace instant development environment using Docker Compose (Currently for Linux)

# What?

This is currently a proof of concept. It aims at offering an easy to install, productivity focused, DSpace development 
environment.

# How?

This project runs on Docker-compose, setting up two containers: one for DSpace development environment and one for Postgres.
The development container should include not only all DSpace's prerequisites but also some tweaks to get faster builds,
deployments and better code hot-swapping. 

# Why?

I believe that setting up a productive development environment for DSpace is non-trivial:
The build system is 'OK' in the sense that it gets the job done, but it doesn't feel right for development. A lot of files get
copied around, compressed, decompressed and compressed again.

Maven itself is not prone to doing things incrementally out of the box. IDEs can help but it steel feels hard to get an
acceptable configuration that avoids full rebuilds. To top that, having the user running ant tasks after maven to get DSpace 
running ensures that your IDE won't understand the full process.

Anyway, it seems that there are lots of things that can be done to hasten the code -> build -> run -> test cycle but it's
kind of messy to do it on your workstation. Having a container that keeps all this customizations in isolation should
encourage experimenting with further tweaks.

# This works on Linux
Docker works on Windows and MacOS too. Most of this 'should' work on Windows and MacOS. The major problem, I believe, are mounted folders. On linux, they just work. On Windows and MacOS, I'm not sure how they are mounted. Docker has been working to improve this integration, but I haven't tested any of this outside linux.

# What's in it for me?

Right now, the major advantages of this build are
- HotSwap Agent integretion, so you can update recompiled classes without restarting tomcat. This should be a MAJOR timesaver while developing.
- Skip jar scanning on Tomcat startup configured by default. This should halve tomcat launch time
- Launch tomcat contexts in parallel. This should make it faster, maybe
- Keep your workspace clean, by putting all of DSpace development dependencies in a container. No more having postgres and tomcat running locally for no reason.
- Seamless filesystem integration (in linux) makes working with the mounted source folder feel just like local development. Avoid the nightmare of running mvn package on a VirtualBox or NFS shared folder (which takes forever) while being able to easily edit source files in an editor running on the host machine.
- Mirage2 ready. Node, Ruby and batteries included. Ready to compile Mirage2 faster with `-Dmirage2.deps.included=false`
- Instant workspace: Launching a full VM takes minutes. Once downloaded and built, docker-compose up takes seconds. Literally. See it to believe it.

# Requirements
- Install [Docker](https://docs.docker.com/engine/installation/)
- Install [Docker Compose](https://docs.docker.com/compose/install/) (Make sure to install the binaries, not the container)
- Have ports 8080 (tomcat), 5432 (postgresql), 1043 and 8000 (remote debugging) open. Otherwise, you can modify the mappings
  in docker-compose.yml file to use whichever ports you prefer.
- Git
- This currently works on Linux (tested in Ubuntu). Docker has announced better integration with OsX and Windows, allowing better volume mounts, which should eventually make this useful in other OSs.
# Launching
- Clone this repo 

        git clone https://github.com/pmarrone/dspace-dev-docker.git
        cd dspace-dev-docker

 - Add a dspace-src folder, where your DSpace code will reside. Also, add m2-repo and dspace-build folders.

        git clone -b dspace-6.0 https://github.com/DSpace/DSpace.git dspace-src
        mkdir m2-repo dspace-build
        
You should end up with the folder structure that dspace-dev-docker expects:

      dspace-dev-docker
      |-- dspace-src
      |-- dspace-build
      +-- m2-repo
      
> If you were to change this names, be aware that changing dspace-dev-docker to something else will affect the 'attach' command later on. If you change dspace-src, dspace-build or m2-repo to a different name, be sure to check those names in the docker-compose.yml file under the volumes settings so that they are mapped correctly.

<!-- -->
> If you fail to create dspace-src, dspace-build and m2-repo folders, Docker will create them for you on startup, but belonging to the ROOT user. Make sure to change ownership of this folders to your user (e.g., sudo chown -R youruser:youruser dspace-src dspace-build m2-repo) or compilation and ant tasks will fail

<!-- -->
> When you run ant tasks, this container expects dspace to be installed on the /srv/dspace folder. Edit your build.properties file in the dspace-src folder so that dspace.install.dir=/srv/dspace. Otherwise, running fresh_install will fail. 

<!-- -->
> You will need to change the db.url property in the build.properties file to ```db.url=jdbc:postgresql://postgres:5432/dspace``` to make the database connection work (notice postgres is used instead of localhost). The expected DB credentials are dspace:dspace for the dspace database.

 - Launch Docker compose and let the magic happen. It takes a while to download the first time you run it.

         docker-compose up -d

 - Once launched, you should be able to attach to the container's bash process. This will get you into a 'developer' account

        docker attach dspacedevdocker_dspace-dev_1

# Doing things

Once inside the container, you can do dspace things, as packaging the project. The container should start on the dspace-src folder. E.g: lets compile DSpace with Mirage2 enabled

    mvn -Dmirage2.on=true -Dmirage2.deps.included=false package

Once compiled, the 'task' alias is available. This basically runs ant using the build.xml found in /srv/dspace-src/dspace/target/dspace-installer/build.xml, so that you don't have to move back and forth to that folder. So, you can run from anywhere

    task fresh_install
    
Also, an alias to the dspace binary is available, so you can run from anywhere

    dspace create-administrator

The tomcat alias is also available, to quickly launch and stop tomcat. The catalina.out alias lauches 'tail' to follow tomcat's log file.

    tomcat start && catalina.out

Since you bound the container's 8080 port to your host, once launched, you can access DSpace xml UI from http://localhost:8080/xmlui/

Tomcat's manager app is also availabe with user: *admin* password: *admin* from http://localhost:8080/manager/
so that you can restart your webapps without restarting tomcat. 
> PSI probe is also installed, but currently broken. I'll get to this eventually

One of the most important benefits of this container right now is that it uses the [DCEVM](https://dcevm.github.io/) patched JVM with [HotswapAgent](http://www.hotswapagent.org/) installed. Just start tomcat with the jpda option

    tomcat jpda start
    
This should get you a tomcat instance running in debugging mode with enhanced hotswapping capabilities. This debugger will be running on port 1043, which is mapped to the host's 1043 port.
Check https://github.com/HotswapProjects/HotswapAgent/wiki/Intellij-IDEA-setup to get an idea of how to set hot-swapping in your IDE, and http://www.javaranch.com/journal/200408/DebuggingServer-sideCode.html to setup remote debugging. This examples
work on IntelliJ, but the setup should be somewhat similar in other IDEs.

# Rough Edges
> "Nothing works out of the box. This project sucks. Your Dockerfile is a mess. You suck. We hate you"
> -- Everyone, all the time

As this project is in a very early stage, there are some annoyances to be taken into account. Some known, some unknown. Hopefully, they will be eventually get ironed out, but, for the time being.

### Now works with DSpace 6.0! It used to work on DSpace 5.5
Currently, some things are harcoded inside Tomcat configuration to work with DSpace 6.0. Check $CATALINA_HOME/conf/Catalina/localhost/ xml files and change reference to whichever version you need. Otherwise, delete those files and run the copy_webapps command alias to copy all webapps to tomcat's webapps folder

### UID is ironed into the Dockerfile
To get things running smoothly, the developer user of the container should match in UID to your current user. It is hardcoded to 1000. If you need to change this (say, your UID is 1009), you will have to rebuild the image with your user ID. Perhaps you can create your own layer to only change this, but, if you want to get up and running quick and dirty, uncomment the following lines in the Dockerfile. This should change the user's UID.

    #Uncomment this lines to set a custom UID. E.g.: 1009
    RUN export uid=1009 && usermod -u $uid developer
    RUN  chown -R developer:developer /home/developer

The idea is to, eventually, move this out of the Dockerfile. If you look a little further up in the Dockerfile, you will notice that you could also change this when the user is created

    #Just change uid and gid to your host user's UID and GID
    RUN export HOME=/home/developer
    RUN export uid=1000 gid=1000 && \
        mkdir -p /home/developer && \
        echo "developer:x:${uid}:${gid}:Developer,,,:/home/developer:/bin/bash" >> /etc/passwd && \
        echo "developer:x:${uid}:" >> /etc/group && \
        echo "developer ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/developer && \
        chmod 0440 /etc/sudoers.d/developer && \
        chown ${uid}:${gid} -R /home/developer
    
### Only xmlui and solr are currently running
Yes, I will get this fixed eventually, if somebody asks for it. If you check $CATALINA_HOME/conf/Catalina/localhost you will notice that just two files exist. xmlui.xml and solr.xml. This should be enough to get a running DSpace instance with XMLUI interface. You can create the missing files to get the other services running, or copy the webapps you need into $CATALINA_HOME/webapps folder. The copy_webapps alias copies all the webapps from /srv/dspace/webapps to that folder. Not thoroughly tested, though.
