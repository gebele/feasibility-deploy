# The Feasibility Triangle


The Feasibility Triangle part of this Repository provides a site (data integration center) with all the neccessary components to set up in order to allow feasibiliy queries from the central feasibility portal.


## Overview

The Feasibility Triangle is composed of three components:

1. A Middleware Client (AKTIN or DSF)
2. A Feasibility Analysis Request Executor (FLARE)
3. A FHIR Server (Blaze)
4. Reverse Proxy (NGINX)

The Feasibility Triangle also comes with a reverse proxy, which provides a basic auth for the FHIR Server and the FLARE component, so that they can be integrated into a sites multi server infrastructure.
The triangle can be set up in different ways depending on which components and whether FHIR Search or CQL is to be used.
This leads to the following setup Options:

AKTIN - FLARE (FHIR Search) - FHIR Server (not CQL ready)
AKTIN - FHIR Server (CQL ready)
DSF - FLARE (FHIR Search) - FHIR Server (not CQL ready)
DSF - FHIR Server (CQL ready)

The components all work with defined interfaces and can be exchanged if a component with equivalent capabilities is provided by the site.
In this manner the FHIR Server provided here (Blaze) can be exchanged for a FHIR server of choice, which either offers CQL or the required FHIR Search capabilities.


## Setting up the Feasibility Triangle

### Step 1 - Installation Docker

The installation of the Feasibility Triangle requires Docker (https://docs.docker.com/engine/install/ubuntu/) and docker-compose (https://docs.docker.com/compose/install/).
If not already installed on your VM, install using the links provided above.

### Step 2 - clone this Repository to your virtual machine

ssh to your virtual machine and switch to sudo `sudo -s`.
Designate a folder for your setup in which to clone the deploy repository, we suggest /opt (`cd /opt`)
Navigate to the directory and clone this repository: `git clone https://github.com/medizininformatik-initiative/feasibility-deploy.git`
Navigate to the feasibility-triangle folder of the repository: `cd /opt/feasibility-deploy/feasibility-triangle`
Checkout the version (git tag) of the feasibility triangle you would like to install: `git checkout tags/<your-tag-name-here>`

### Step 3 - Initialise .env files

The feasibility portal requires .env files for the docker-compose setup. If you are setting up the project new and have not done so yet execute the `initialise-triangle-env-files.sh`.

If you have set up the portal before compare the .env to the .env.default env files of each component and copy the additional params as appropriate

### Step 4 - Set Up basic auth

To set up basic auth you can execute the `setup-base-auth.sh <username> <password>` to add a simple .htpasswd to protect your FHIR Server and FLARE component with basic authentication.
This creates a .htpasswd file in the `auth` directory, which will be mounted to the nginx, which is part of this deployment repository.

### Step 5 - Set Up ssl certificates

Running this setup safely at your site, requires a valid certificate and domain. Please contact the responsible body of your institution to recieve both a domain and certificate.
You will require two .pem files: a cert.pem (certificate) and key.pem (private key).

Once you have the appropriate certificates you should save them under `/opt/feasibility-deploy/feasibility-triangle/auth`.
Set the rights for all files of the auth folder to 655 `chmod 655 /opt/feasibility-deploy/feasibility-triangle/auth/*`.  

- If you do not provide a cert.pem and key.pem file the reverse proxy will not start up, as it will not be able to provide a secure https connection.
- The rest of the feasibility triangle will still work, as it does create a connection to the outside without the need to make itself accessible. 
- However, if you would for example load data into the FHIR server from an ETL job on another VM you will need to expose the FHIR server via a reverse proxy, which will require the certificates above.

### Step 6 - Load the ontology mapping files

If used, (see "Overview") The FLARE component requires a mapping file and ontology tree file to translate an incoming feasibility query into FHIR Search queries.
Both can be downloaded here: https://confluence.imi.med.fau.de/display/ABIDEMI/Ontologie

Upload the ontology .zip files to your server, unpack them and copy the ontology files to your 

```bash
sudo -s
mkdir /<path>/<to>/<folder>/<of>/<choice>
cd /<path>/<to>/<folder>/<of>/<choice>
unzip mapping_*.zip
cd mapping
cp * /opt/feasibility-deploy/feasibility-triangle/ontology
```

### Step 7 - Configure your feasibility triangle

If you use the default triangle setup you only have to configure the AKTIN client to connect to the central feasibility portal as the rest of the setup will already be correctly configured for you.

To configure the AKTIN client in the default setup, change the following environment variables in the file `/opt/feasibility-deploy/feasibility-triangle/aktin-client/.env` according to the paragraph **Configurable environment variables** of this README:

- FEASIBILITY_AKTIN_CLIENT_BROKER_ENDPOINT_URI
- FEASIBILITY_AKTIN_CLIENT_AUTH_PARAM
- FEASIBILITY_AKTIN_CLIENT_WEBSOCKET_PING_SECONDS

If you are using AKTIN, as in the default setup you have to adjust the rights of the aktin-requests.log file to allow the AKTIN container user to write the logs as follows:
`chown 10001:10001 /opt/feasibility-deploy/feasibility-triangle/aktin-client/aktin-requests.log`

### Step 8 - Start the feasibility triangle

To start the triangle navigate to `/opt/feasibility-deploy/feasibility-triangle` and
execute `bash start-triangle.sh`.

This starts the following default triangle: 
AKTIN (Middleware) - FLARE (FHIR Search executor) - BLAZE (FHIR Server)

- AKTIN: Used to connect to the central platform and allow queries from the Zars
- FLARE: A Rest Service, which is needed to translate, execute and evaluate a feasibility query on a FHIR Server using FHIR Search
- BLAZE: The FHIR Server which holds the patient data for feasibility queries


If you would like to pick other component combinations you can start each component individually by setting your compose project (`export FEASIBILITY_COMPOSE_PROJECT=feasibility-deploy`)
navigating to the respective components folder and executing: 
`docker-compose -p $FEASIBILITY_COMPOSE_PROJECT up -d`


### Step 9 - Access the Triangle

In the default coniguration and given that you have set up a ssl certifcate in step 4 the setup will expose the following services:

These are the URLs for access to the webclients via nginx:

| Component   | URL                              | User             | Password         |
|-------------|----------------------------------|------------------|------------------|
| Flare       | <https://your-domain/flare>      | chosen in step 3 | chosen in step 3 |
| FHIR Server | <https://your-domain/fhir>       | chosen in step 3 | chosen in step 3 |

Accessible service via localhost:

| Component   | URL                              | User             | Password         |
|-------------|----------------------------------|------------------|------------------|
| Flare       | <http://localhost:8084>          | None required    | None required    |
| FHIR Server | <http://localhost:8081>          | None required    | None required    |

Please be aware, that if you would like to access the services on localhost without a password you will need to set up an ssh tunnel to your server and forward the respective ports.

For example for the FHIR Server: ssh -L 8081:127.0.0.1:8081 your-username@your-server-ip

### Step 10 - Init Testdata (Optional)

To initialise testdata execute the `get-mii-testdata.sh`. This will download MII core dataset conformant testdata from <https://github.com/medizininformatik-initiative/kerndatensatz-testdaten>
unpack it and save them to the testdata folder of this repository.

You can then load the data into your FHIR Server using the `upload-testdata.sh` script.

### Configurable environment variables

| Env Variable   | Description                     | Default             | Possible Values | Component         |
|-------------|----------------------------------|------------------|------------------|------------------|
|FEASIBILITY_AKTIN_CLIENT_BROKER_REQUEST_MEDIATYPE|The media type of the query you would like to handle|application/sq+json|application/sq+json, text/cql|AKTIN|
|FEASIBILITY_AKTIN_CLIENT_BROKER_RESULT_MEDIATYPE|The media type of the query response you return|application/json|application/json|AKTIN|
|FEASIBILITY_AKTIN_CLIENT_BROKER_ENDPOINT_URI|The URL of the AKTIN broker endpoint|http://aktin-broker:8080/broker/|URL|AKTIN|
|FEASIBILITY_AKTIN_CLIENT_AUTH_CLASS|Type of authentication used by AKTIN|org.aktin.broker.client2.auth.ApiKeyAuthentication|org.aktin.broker.client2.auth.ApiKeyAuthentication|AKTIN|
|FEASIBILITY_AKTIN_CLIENT_AUTH_PARAM|The API key of your site|xxxApiKey123|API key token|AKTIN|
|FEASIBILITY_AKTIN_CLIENT_WEBSOCKET_PING_SECONDS|The time in which your AKTIN client pings the AKTIN broker to ensure idle websocket conections stay open|60|Integer (seconds)|AKTIN|
|FEASIBILITY_AKTIN_CLIENT_WEBSOCKET_RECONNECT_SECONDS||10|Integer (seconds)|AKTIN|
|FEASIBILITY_AKTIN_CLIENT_WEBSOCKET_RECONNECT_POLLING||TRUE||AKTIN|
|FEASIBILITY_AKTIN_CLIENT_PROCESS_TIMEOUT_SECONDS|The timeout within which a process has to return before the client sends a "failed" message to the AKTIN broker|60|Integer (seconds)|AKTIN|
|FEASIBILITY_AKTIN_CLIENT_PROCESS_COMMAND|The command to be executed on recieving a feasibility query. Allows one to switch between flare and cql execution|/opt/aktin/call-flare.sh|/opt/aktin/call-flare.sh, /opt/aktin/call-cql.sh|AKTIN|
|FEASIBILITY_AKTIN_CLIENT_PROCESS_ARGS||10|Integer (seconds)|AKTIN|
|FEASIBILITY_AKTIN_CLIENT_FLARE_BASE_URL|the URL of the FLARE component if used|http://flare:8080|URL|AKTIN|
|FEASIBILITY_AKTIN_CLIENT_OBFUSCATE|Sets whether the AKTIN Client should obfuscate the results (response) of a feasibility query|TRUE|true or false|AKTIN|
|FEASIBILITY_AKTIN_JAVA_OPTS|Provides Java options to the AKTIN client - can be used to configure proxy use. For example : " Dhttps.proxyHost=squid -Dhttps.proxyPort=3128"||valid java options|AKTIN|
|FEASIBILITY_AKTIN_CLIENT_FHIR_AUTH_USER|basic auth user to connect to FHIR server if CQL is used|||AKTIN|
|FEASIBILITY_AKTIN_CLIENT_FHIR_AUTH_PW|basic auth password to connect to FHIR server if CQL is used|||AKTIN|
|FEASIBILITY_AKTIN_FHIR_BASE_URL|FHIR server base url the AKTIN client is to use to connect to the FHIR server|http://fhir-server:8080/fhir||AKTIN|
|FHIR_SERVER_BASE_URL|The base URL of the FHIR server the fhir server uses to generate next links|http://fhir-server:8080||BLAZE|
|FHIR_SERVER_LOG_LEVEL|log level of the FHIR server|debug|debug, info, error|BLAZE|
|BLAZE_JVM_ARGS|see: https://github.com/samply/blaze/blob/master/docs/deployment/environment-variables.md|-Xmx4g||BLAZE|
|BLAZE_BLOCK_CACHE_SIZE|see: https://github.com/samply/blaze/blob/master/docs/deployment/environment-variables.md|256||BLAZE|
|BLAZE_DB_RESOURCE_CACHE_SIZE|see: https://github.com/samply/blaze/blob/master/docs/deployment/environment-variables.md|2000000||BLAZE|
|BLAZE_DB_RESOURCE_HANDLE_CACHE_SIZE|see: https://github.com/samply/blaze/blob/master/docs/deployment/environment-variables.md|100000||BLAZE|
|PORT_FHIR_SERVER_LOCALHOST|The exposed docker port of the FHIR server|127.0.0.1:8081|should always include 127.0.0.1|BLAZE|
|FEASIBILITY_FLARE_PORT|The exposed docker port of the FLARE componenet|127.0.0.1:8084|should always include 127.0.0.1|FLARE|
|FLARE_FHIR_SERVER_URL|The Url of the FHIR server FLARE uses to connect to the FHIR server|http://fhir-server:8080/fhir/|URL|FLARE|
|FLARE_FHIR_USER|basic auth user to connect to FHIR server|||FLARE|
|FLARE_FHIR_PW|basic auth password to connect to FHIR server if CQL is used|||FLARE|
|FLARE_FHIR_PAGE_COUNT|The number of resources per page FLARE asks for from the FHIR server|500||FLARE|
|FLARE_EXEC_CORE_POOL_SIZE|The core thread pool size|4|Integer|FLARE|
|FLARE_EXEC_MAX_POOL_SIZE|The max thread pool size|16|Integer|FLARE|
|FLARE_EXEC_KEEP_ALIVE_TIME_SECONDS|The time threads are kept alive|10|Integer|FLARE|
|FLARE_LOG_LEVEL|log level of flare|debug|off, fatal, error, warn, info, debug, trace|FLARE|
|FEASIBILITY_TRIANGLE_REV_PROXY_PORT|The exposed docker port of the reverse proxy - set to 443 if you want to use standard https and you only have the feasibility triangle installed on your server|444|Integer (valid port)|REV Proxy|
