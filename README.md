
So far i’m thinking:

Quick Run through 101/MOOC CC Training

Cluster Templates:
- Custom cluster templates in general
  a) security policies
  b) multiple nodearrays
  c) filers, redis, etc.
- Linking clusters with search
   a) standalone NFS
   b) standalone redis

Pogo:
- Configure pogo for use with Projects

Projects:
- Add a custom application project
  a) project structure and chef vs cluster-init
  b) how to develop projects
- Adding capabilies to nodes via projects
   a) add GPU drivers
   b) anyone have a project that installs Intel MPI?

Common Tasks:
- CycleServer Users vs Cluster OS Users
   a) CycleServer User Roles
   b) Cluster Sharing
- Cluster user creation
   a) create_users cookbook
   b) Azure AD

Plugins:
- basic REST API plugin
- command plugin

Operations:
- querying the Datastore (./cycle_server)
  a) cycle_server execute
  b) cycle_server history
- cost alerts
- custom alerts
  - Alert when specific service has failures
- debugging
   a) converge failures
   b) unreachable nodes
   c) recovering from CC failures (maybe)