# demogenetrix
A script to automatically create a new demo/sandbox on lagoon

## Setup

### Clone script to your local

I put it in the same directory that houses all my local sites and sandboxes

### Add your github token to it

Open new_demo.sh
On the line GITHUB_TOKEN="$GITHUB_TOKEN", replace $GITHUB_TOKEN with your github token.

At some point, I will update the script to locate this value elsewhere, but for now we're doing it a bit cowboy style

## Run the script

Run with bash from the directory where you want your site to live, pointing bash to where the demogenetrix script lives

`bash demogenetrix/new_demo.sh`

## Creating a new project from scratch

### Name your Project

Enter a name for the project (this will also be the directory name of your local project):

### Clone from a lagoon_examples repo

Do you want to clone a repo? (yes/no):

Select a Git repository to clone:
0. git@github.com:lagoon-examples/drupal-base
1. git@github.com:lagoon-examples/drupal-solr.git
2. git@github.com:lagoon-examples/drupal9-full.git
3. git@github.com:amazeeio-demos/demo-node-simple.git
4. git@github.com:amazeeio-demos/demo-nextdrupal-drupal.git
5. git@github.com:amazeeio-demos/demo-nextdrupal-nextjs.git
Enter the number corresponding to the repository:

### Rename example files to match your new project name

Do you want to rename the project files and replace references to the old project name? (yes/no):

### Create a new repo in amazeeio-sales

Do you want to create a new repo and push up your local changes? (yes/no):

### Create a new Lagoon project

Do you want to create a new Lagoon project? (yes/no):

### Connect your new github repo to your new Lagoon project (Webhook + deploy key)

Do you want to connect Lagoon to github? (yes/no):

### Add new Lagoon users to your project

Do you want to add a user? (yes/no):

## Re-running the script on an existing local site

## Manual steps for finishing site setup

Now run:
pygmy up
docker build
docker-compose up -d
docker-compose exec cli composer install
docker-compose exec cli drush si demo_umami -y
docker-compose exec cli drush la
docker-compose exec cli drush sql-sync @self @lagoon.[project]-[env]
docker-compose exec cli drush rsync @self:%files @lagoon.[project]-[env]:%files

### If NextDrupal...

#### Drupal -

##### edit these files:

```
diff --git a/.lagoon.yml b/.lagoon.yml
index 6f5090f..5c85518 100644
--- a/.lagoon.yml
+++ b/.lagoon.yml
@@ -36,11 +36,11 @@ tasks:

 environments:
   main:
-    routes:
-      - nginx:
-        - "drupal.demo.composetheweb.com":
-            tls-acme: true
-            insecure: Redirect
+    #routes:
+    #  - nginx:
+    #    - "drupal.demo.composetheweb.com":
+    #        tls-acme: true
+    #        insecure: Redirect
     cronjobs:
       - name: drush cron
         schedule: "*/15 * * * *"
```

```
diff --git a/docker-compose.yml b/docker-compose.yml
index 55cfde4..a477b2e 100644
--- a/docker-compose.yml
+++ b/docker-compose.yml
@@ -67,7 +67,7 @@ services:
     networks:
       amazeeio-network:
         aliases:
-          - drupal-composetheweb
+          - drupal-[PROJECT-NAME]-composetheweb
       default:

   php:
```

##### run these steps

start up services + containers

```
pygmy up
docker-compose up -d
docker-compose exec cli composer install
docker-compose exec cli drush la
docker-compose exec cli drush sql-sync @lagoon.demo-nextdrupal-drupal-main @self
docker-compose exec cli drush rsync @lagoon.demo-nextdrupal-drupal-main:%files @self:%files
pygmy status
```

enable modules

```
docker-compose exec cli drush uli
docker-compose exec cli drush en jsonapi_menu_items jsonapi_views next_jsonapi
docker-compose exec cli drush cex
#### NextJS - 
edit these files
```

#### NextJS -

##### edit these files: