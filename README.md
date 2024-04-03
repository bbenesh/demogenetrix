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