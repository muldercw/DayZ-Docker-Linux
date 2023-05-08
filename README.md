# DayZ-Docker-Linux
Run DayZ Server in a linux container

# Usage

**1**
Clone this repository to your server
```
git clone https://github.com/EA-Gaming/DayZ-Docker-Linux.git
cd ./DayZ-Docker-Linux
```

**2**
Copy the template myserver.env to a new file (mynewserver.env for example) and edit the variables
```
cp myserver.env mynewserver.env
```

**3**
Build the image, this will use steamcmd to download the DayZ Server files
```
docker-compose build --env-file mynewserver.env
```

**4**
Start the container once to create the config;missions;profiles folders for your server
```
docker-compose up --env-file mynewserver.env --entrypoint /bin/bash --command quit
```

**5**
Default files will have been created in config/mynewserver and missions/mynewserver.
Edit these as required or copy your existing files into these folders.

Note, the config directories file names must be kept the same. Make sure the mission folder is correctlt referenced.