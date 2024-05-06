# General Purpose Reverse Proxy for Snowpark Container Services
This repo is an example of a general purpose reverse proxy
using nginx to gather multiple services deployed in Snowpark
Container Services under a single exposed ingress endpoint URL.

One use case for this is to allow a frontend applicaiton (e.g.,
a React web app hosted in one container/service) to make
API calls to an API hosted in another container/service. This
can be challenging given the strict CORS policy that Snowpark
Container Services imposes on exposed ingress endpoints.

The idea is to create all services in Snowpark Container Services
with only private endpoints, and then this "router service" will
use nginx to proxy those internal endpoints via a route on the
one exposed ingress URL. This will make it appear that all of the
services are exposed on the same ingress URL and get around 
challenges like CORS.

One note: if your use case is to expose multiple frontends on
the same "router service", the frontends must have the same
path on their service as the path you want to use in the "router
service". That is, if you want the route on the "router service"
to be `/app1`, then the service itself must serve that application
also on `/app1`. This is because some applications use relative
paths, and that can get difficult using a reverse proxy, like
nginx.

## Setup
1. Follow the "Common Setup" [here](https://docs.snowflake.com/developer-guide/snowpark-container-services/tutorials/common-setup)
2. In a SQL Worksheet, execute `SHOW IMAGE REPOSITORIES` and look
   for the entry for `TUTORIAL_DB.DATA_SCHEMA.TUTORIAL_REPOSITORY`.
   Note the value for `repository_url`.
3. In the main directory of this repo, execute 
   `./configure.sh`. Enter the URL of the repository that you
   noted in step 2 for the repository. 
4. Log into the Docker repository, build the Docker image, and push
   the image to the repository by running `make all`
   1. You can also run the steps individually. Log into the Docker 
      repository by running `make login` and entering your credentials.
   2. Make the Docker image by running `make build`.
   3. Push the image to the repository by running `make push`

### Create the Service
To create the router service, you will need the names of the Snowpark
Container Services that you want to proxy, as well as the endpoint ports
for those services. We will map these internal endpoints/ports to 
paths on the router service in the YAML specification for the router
service.

The way we are going to configure the router service is by passing in 
pairs of "path" and "route". The "path" is the URL path for the 
router service ingress URL (include the leading `/`; e.g., `/api`). 
The "route" is the internal route to reverse
proxy to, and includes the protocol (e.g., `http://`), the service name
or fully-qualified DNS name (e.g., `service1` or 
`db1.schema1.service1.snowflakecomputing.internal`), and the port (e.g., `80`).

These pairs are sent to the container as arugments in the YAML
specification:
```
spec:
  containers:
    - name: router
      image: repodb/reposchema/repo/spcs_router
      args:
        - /=http://frontend:80
        - /api=http://backenddb.backendschema.backend.snowflakecomputing.internal:8888
  endpoints:
    - name: router
      port: 80
      public: true
```

The Makefile includes a `ddl` target that will show the DDL command
template for creating the service. An example output is:

```
CREATE SERVICE router
  IN COMPUTE POOL  tutorial_compute_pool
  FROM SPECIFICATION $$
spec:
  containers:
    - name: router
      image: repodb/reposchema/repo/spcs_router
      args:
        - /=http://frontend:80
        - /api=http://backenddb.backendschema.backend.snowflakecomputing.internal:8888
  endpoints:
    - name: router
      port: 80
      public: true
  $$
;
```

If any of the proxied services need EXTERNAL ACCESS INTEGRATIONS for 
Content Security Policy (CSP) reasons, make sure to add those to the DDL 
for the proxy service.
