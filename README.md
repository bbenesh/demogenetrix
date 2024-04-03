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

### Create a new repo in amazeeio-demos

Do you want to create a new repo and push up your local changes? (yes/no):

### Create a new Lagoon project

Do you want to create a new Lagoon project? (yes/no):

### Connect your new github repo to your new Lagoon project (Webhook + deploy key)

Do you want to connect Lagoon to github? (yes/no):

### Add new Lagoon users to your project

Do you want to add a user? (yes/no):

## Re-running the script on an existing local site

## Manual steps for finishing site setup

### Plain Drupal

Now run:

```
pygmy up
docker build
docker-compose up -d
docker-compose exec cli composer install
docker-compose exec cli drush si demo_umami -y
docker-compose exec cli drush la
docker-compose exec cli drush sql-sync @self @lagoon.[project]-[env]
docker-compose exec cli drush rsync @self:%files @lagoon.[project]-[env]:%files
```

### If NextDrupal...

#### Drupal -

##### 1. edit these files

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

##### 2. run these steps

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

##### 1. edit these files

```
diff --git a/.lagoon.env.main b/.lagoon.env.main
index 4c569bb..b78ebbb 100644
--- a/.lagoon.env.main
+++ b/.lagoon.env.main
@@ -1,7 +1,7 @@
-NEXT_PUBLIC_DRUPAL_BASE_URL=https://drupal.demo.composetheweb.com
-NEXT_IMAGE_DOMAIN=drupal.demo.composetheweb.com
+NEXT_PUBLIC_DRUPAL_BASE_URL=https://nginx.main.demo-[PROJECT-NAME]-nextdrupal-drupal.us2.amazee.io
+NEXT_IMAGE_DOMAIN=nginx.main.demo-[PROJECT-NAME]-nextdrupal-drupal.us2.amazee.io
 DRUPAL_PREVIEW_SECRET=secret
 NEXTAUTH_SECRET=
-NEXTAUTH_URL=https://drupal.demo.composetheweb.com
+NEXTAUTH_URL=https://nginx.main.demo-[PROJECT-NAME]-nextdrupal-drupal.us2.amazee.io
 DRUPAL_CLIENT_ID=
 DRUPAL_CLIENT_SECRET=
```

```
diff --git a/.lagoon.yml b/.lagoon.yml
index fe5240a..99c89a8 100644
--- a/.lagoon.yml
+++ b/.lagoon.yml
@@ -1,10 +1,10 @@
 docker-compose-yaml: docker-compose.yml
 project: demo-[PROJECT-NAME]-nextdrupal-nextjs

-environments:
-  main:
-    routes:
-      - node:
-        - "next.demo.composetheweb.com":
-            tls-acme: true
-            insecure: Redirect
+#environments:
+#  main:
+#    routes:
+#      - node:
+#        - "next.demo.composetheweb.com":
+#            tls-acme: true
+#            insecure: Redirect
```

##### 2. run these steps

cp .env.example to .env.local
update the values in the file

```
-NEXT_PUBLIC_DRUPAL_BASE_URL=http://drupal-composetheweb:8080
-NEXT_IMAGE_DOMAIN=drupal-composetheweb
+NEXT_PUBLIC_DRUPAL_BASE_URL=http://drupal-[PROJECT-NAME]-composetheweb:8080
+NEXT_IMAGE_DOMAIN=drupal-[PROJECT-NAME]-composetheweb
 DRUPAL_PREVIEW_SECRET=secret
 NEXTAUTH_SECRET=
 NEXTAUTH_URL=http://demo-[PROJECT-NAME]-nextdrupal-nextjs.docker.amazee.io
```

start up services + containers

```
docker-compose build
docker-compose run -u 1002 node sh
$ npm install     <==== in the container
$ ctrl-d      
docker-compose up
```