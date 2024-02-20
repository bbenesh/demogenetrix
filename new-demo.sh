#!/bin/bash

#//TODO - store token separately
#//TODO - test local spin up with docker
#//TODO - install composer req + db
#//TODO - push local files + db up to remote lagoon
#//TODO - pull all available repos from lagoon examples as options
#//TODO - Add to amazeeio-sales group + Org (when Orgs are ready)
#//TODO - Prompt for custom group
#//TODO - edit output for better readibility and letting the user know what's happening
#//TODO - add ending message to alert user that script is done
#//TODO - fix webhook not adding pull request rights
#//TODO - do site install either locally or on remote
#//TODO - export config, commit and push up
#//TODO - uncomment and update post rollout tasks

# 1. Setup req's for script

  # Make sure to replace YOUR_GITHUB_TOKEN with your actual GitHub token. 
  # Also, ensure that the jq command-line JSON processor is installed on your system, 
  # as it is used to parse the response from the GitHub API.
  # brew install jq 

  # the script expects the GITHUB_TOKEN environment variable to be set before running. 
  # You can set the environment variable in your shell before executing the script:
  #
  # export GITHUB_TOKEN="your_actual_token_value"
  # ./your_script.sh
  #
  # If you set the environment variable in your shell session using export GITHUB_TOKEN="your_actual_token_value", 
  # it will only be available for the duration of that shell session. 
  # Once you close the terminal or open a new session, the environment variable will no longer be set.
  #
  # To avoid having to set the environment variable every time you run the script or open a new session, you can consider adding the export statement to your shell profile configuration file. The exact file depends on the shell you are using:
  #
  # For Bash, you can add the export statement to your ~/.bashrc or ~/.bash_profile file.
  # For Zsh, add it to your ~/.zshrc file.
  # For Fish, add it to your ~/.config/fish/config.fish file.
  # For example, if you're using Bash, you can add the following line to your ~/.bashrc or ~/.bash_profile:
  #
  # bash
  # Copy code
  # export GITHUB_TOKEN="your_actual_token_value"
  #
  # After saving the file, restart your terminal or run source ~/.bashrc (or source ~/.bash_profile depending on your setup), and the environment variable will be set automatically whenever you open a new shell session.
  #
  # Remember to replace "your_actual_token_value" with your GitHub token.


# CONSTANTS

  # GitHub organization and token
  GITHUB_ORGANIZATION="amazeeio-demos"
  WEBHOOK_URL="https://hooks.lagoon.amazeeio.cloud"
  # Demo Creator Script Token
  # GITHUB_TOKEN="$GITHUB_TOKEN"
  
# Prompt user for project name
read -p "Enter a name for the project (this will also be the directory name of your local project): " project_name

# //TODO make a function to detect remote origin url if we are not creating a new repo

# 2. Clone repo to local

  # Function to clone repository
  clone_repository() {
    local project_name="$1"
    # Define Git repository URLs
    local repos=(
      "git@github.com:lagoon-examples/drupal-base" 
      "git@github.com:lagoon-examples/drupal-solr.git"
      "git@github.com:lagoon-examples/drupal9-full.git"
    ) 
    local choice

    # Display menu to choose a repository
    echo "Select a Git repository to clone:"
    for i in "${!repos[@]}"; do
      echo "$i. ${repos[$i]}"
    done

    # Prompt user for repository choice
    read -p "Enter the number corresponding to the repository: " choice

    # Validate user input
    if ! [[ $choice =~ ^[0-9]+$ ]] || (( choice < 0 || choice >= ${#repos[@]} )); then
      echo "Invalid input. Please enter a valid number."
      exit 1
    fi

    # Prompt user for directory name
    # read -p "Enter a name for the directory: " dir_name

    # Clone the chosen repository into the specified directory
    git clone "${repos[$choice]}" "$project_name"

    # Check if the clone was successful
    if [ $? -eq 0 ]; then
      echo "Repository cloned successfully into '$project_name' directory."
    else
      echo "Failed to clone repository. Please check the repository URL and try again."
      exit 1
    fi
  }

# 3. Rename files and replace references to old project name

  # Function to rename files and replace reference to old project name
  rename_files_and_replace_references() {
    local project_name="$1"

    # Echo the current working directory
    echo "Current working directory: $(pwd)"
    # Change directory to the one with the same name as project_name
    cd "$project_name" || { echo "Failed to change directory."; exit 1; }
    echo "New working directory: $(pwd)"


    # Get the remote origin URL of the Git repository
    local repo_url
    repo_url=$(git config --get remote.origin.url)
    
    local search_string
    local modified_string

    # Extract the part of the repo string after the last /
    #search_string=$(echo "${repos[$choice]}" | awk -F'/' '{print $NF}' | sed 's/\.git$//')
    search_string=$(basename "$repo_url" | sed 's/\.git$//')

    # Use grep to search for the string in all files and replace it
    #grep -rli "$search_string" "$project_name" | xargs sed -i '' -e "s/$search_string/$project_name/g"
    grep -rli "$search_string" | xargs sed -i '' -e "s/$search_string/$project_name/g"

    # Remove spaces and dashes from the original string
    modified_string=$(echo "$search_string" | tr -d '[:space:]' | tr -d '-')

    # Use grep to search for the modified string in all files and replace it
    #grep -rli "$modified_string" "$project_name" | xargs sed -i '' -e "s/$modified_string/$project_name/g"
    grep -rli "$modified_string" | xargs sed -i '' -e "s/$modified_string/$project_name/g"

    echo "Repo url: '$repo_url'"
    echo "String '$search_string' and '$modified_string' replaced with '$project_name' in all files."
  }

# 4. Create a new repo, add local changes, and push up

  # Function to create a new repo, add local changes, and push up
  create_and_push_repo() {
    local project_name="$1"
    local create_repo_response
    local repo_url
    local current_dir
    current_dir=$(basename "$(pwd)")

    if [[ "$current_dir" != "$project_name" ]]; then
        # Change into the newly cloned directory
        cd "$project_name" || { echo "Failed to change directory."; exit 1; }
    fi

    # Create a new GitHub repository using the GitHub API
    echo "Create a new GitHub repository using the GitHub AP"
    # echo "curl -s -H Authorization: token $GITHUB_TOKEN" -d '{"name": "'"$project_name"'", "private": true}' "https://api.github.com/orgs/$GITHUB_ORGANIZATION/repos"
    create_repo_response=$(curl -s -H "Authorization: token $GITHUB_TOKEN" -d '{"name": "'"$project_name"'", "private": true}' "https://api.github.com/orgs/$GITHUB_ORGANIZATION/repos")
    echo $create_repo_response

    # Extract the new repository URL
    echo "Extract the new repository URL"
    repo_url=$(echo "$create_repo_response" | jq -r '.ssh_url')
    echo $repo_url

    # Remove the old remote origin
    git remote remove origin

    # Add the new remote origin
    git remote add origin "$repo_url"

    # Add and commit local changes
    git add .
    git commit -m "Project init."

    # Push everything to the main branch on the new repo
    git push -u origin main

    echo "Repository '$project_name' pushed to the new GitHub repository in the '$GITHUB_ORGANIZATION' organization."
  }

  # Function to retrieve remote origin URL if skipped create_and_push_repo step
  # get_remote_origin_url() {
  #     local project_name="$1"
  #     local current_dir
  #     current_dir=$(basename "$(pwd)")

  #     if [[ "$current_dir" == "$project_name" ]]; then
  #       repo_url=$(git config --get remote.origin.url)
  #     else
  #       cd "$project_name" || { echo "Failed to change directory."; exit 1; }
  #       repo_url=$(git config --get remote.origin.url)
  #       #cd ..
  #     fi
  # }

# 5. Create Lagoon project

  # Function to create Lagoon project
  create_lagoon_project() {
    local project_name="$1"
    local current_dir
    current_dir=$(basename "$(pwd)")

      if [[ "$current_dir" == "$project_name" ]]; then
        repo_url=$(git config --get remote.origin.url)
      else
        cd "$project_name" || { echo "Failed to change directory."; exit 1; }
        repo_url=$(git config --get remote.origin.url)
        #cd ..
      fi
    
    echo 'Creating lagoon project "'$project_name'" -b "^(main|dev|feature.*)$" -g "'$repo_url'" -S 126 -m true -E main'
    lagoon add project -p "$project_name" -b "^(main|dev|feature.*)$" -g "$repo_url" -S 126 -m true -E main
  }

# 6. Connect Lagoon project to Git repo
  
  # Deploy Key

    # Function to add deploy key to the repository
    add_deploy_key_to_repo() {
      local project_name="$1"

      # Run the 'lagoon get project-key' command and capture the output
      project_key=$(lagoon get project-key -p "$project_name")

      # Extract the public key from the output and remove the leading "PUBLICKEY "
      public_key=$(echo "$project_key" | sed 's/PUBLICKEY //')

      # Print the extracted public key for debugging
      echo "Extracted public key: $public_key"

      # Construct the JSON data
      json_data=$(jq -n --arg title "Lagoon Deploy Key" --arg key "$public_key" --argjson read_only true '{"title": $title, "key": $key, "read_only": $read_only}')

      # Add the deploy key to the new repository using the GitHub API
      deploy_key_response=$(curl -s -H "Authorization: token $GITHUB_TOKEN" -H "Content-Type: application/json" -X POST -d "$json_data" "https://api.github.com/repos/$GITHUB_ORGANIZATION/$project_name/keys" | jq '.')

      # Print the GitHub API response for debugging
      echo "GitHub API response: $deploy_key_response"

      echo "Deploy key added to the new repository in the '$GITHUB_ORGANIZATION' organization."
    }

  # Webhook

    # Function to add webhook to the repository
    add_webhook_to_repo() {
      local project_name="$1"

      # //TODO: Fix that it's only selecting the push event

      # Construct the JSON data for the webhook
      webhook_data=$(jq -n --arg url "$WEBHOOK_URL" '{"name": "web", "config": {"url": $url, "content_type": "json"}, "events": ["push"], "active": true}')

      # Add a webhook to the new repository using the GitHub API
      webhook_response=$(curl -s -H "Authorization: token $GITHUB_TOKEN" -H "Content-Type: application/json" -X POST -d "$webhook_data" "https://api.github.com/repos/$GITHUB_ORGANIZATION/$project_name/hooks" | jq '.')

      # Print the GitHub API response for the webhook for debugging
      echo "GitHub API response (Webhook): $webhook_response"

      echo "Webhook added to the new repository in the '$GITHUB_ORGANIZATION' organization."
    }

  # Function to connect Lagoon project to Git repo
  connect_lagoon_project_to_git() {
    local project_name="$1"

    # Deploy Key
    add_deploy_key_to_repo "$project_name"

    # Webhook
    add_webhook_to_repo "$project_name"

    # Trigger build
    git commit -m "Trigger build." --allow-empty
    git push origin main

    # Add Lagoon project to group and/or Organization
    # //TODO: split this out into a separate function
    lagoon add project-group -p "$project_name" -N amazeeio-sales

    # //TODO: - Figure out Organizations
  }

# 7. Add users to Lagoon + group

  # //TODO: Handle custom groups

  # Function to collect user email and name
    collect_user_info() {
      # Prompt user for email, first name, and last name
      read -p "Enter your email address: " email
      read -p "Enter your first name: " first_name
      read -p "Enter your last name: " last_name
    }

  # Function to create Lagoon user and add to group
  add_user_to_lagoon() {
    local project_name="$1"

    # Assuming you have a command that takes email, first name, and last name as arguments
    echo "Running command with provided information:"
    echo "Email: $email"
    echo "First Name: $first_name"
    echo "Last Name: $last_name"
    echo "Group: project-$project_name" 
    
    # Create user... 
    echo "Creating user.."
    lagoon add user -E "$email" -F "$first_name" -L "$last_name"

    # And add user to default project group
    echo "Adding user to group project-n"$project_name"..."
    lagoon add user-group -E "$email" -N project-$project_name -R owner
  }

  # Function to ask the user if they want to add another user
  add_another_user() {
    read -p "Do you want to add another user? (yes/no): " answer
    if [ "$answer" = "yes" ]; then
      return 0  # User wants to run again
    else
      return 1  # User does not want to run again
    fi
  }

# Main script
main() {

  # Clone repo?
  read -p "Do you want to clone a repo? (yes/no): " clone_repo
  if [ "$clone_repo" = "yes" ]; then
    clone_repository "$project_name"
  else
    echo "Skipping repo clone"
  fi

  # Rename files?
  read -p "Do you want to rename the project files and replace references to the old project name? (yes/no): " rename_files
  if [ "$rename_files" = "yes" ]; then
    rename_files_and_replace_references "$project_name"
  else
    echo "Skipping renaming"
  fi

  # Create new repo, push up local changes
  read -p "Do you want to create a new repo and push up your local changes? (yes/no): " new_repo
  if [ "$new_repo" = "yes" ]; then
    create_and_push_repo "$project_name"
  else
    echo "Skipping new repo + push"
    #get_remote_origin_url "$project_name"
  fi

  # Create Lagoon project?
  read -p "Do you want to create a new Lagoon project? (yes/no): " lagoon_project
  if [ "$lagoon_project" = "yes" ]; then
    create_lagoon_project "$project_name"
  else
    echo "Skipping create lagoon project"
  fi

  # Connect Lagoon to github?
  read -p "Do you want to connect Lagoon to github? (yes/no): " connect_lagoon
  if [ "$connect_lagoon" = "yes" ]; then
    connect_lagoon_project_to_git "$project_name"
  else
    echo "Skipping connect lagoon project to git"
  fi

  # Add user(s)?
  # //TODO: Refactor to ask if you want to add a new user, or add existing user to group
  read -p "Do you want to add a user? (yes/no): " add_user
  if [ "$add_user" = "yes" ]; then
    while true; do
      # Collect user information
      collect_user_info

      # Run a command using collected user information
      add_user_to_lagoon "$project_name"

      # Ask if the user wants to add another user
      add_another_user
      if [ $? -eq 0 ]; then
        echo "Adding another user..."
      else
        echo "Moving on..."
        break
      fi
    done
  else
    echo "Skipping user addition."
  fi

  #//TODO - turn this into functions
  echo "Now run:"
  echo "pygmy up"
  echo "docker build"
  echo "docker-compose up -d"
  echo "docker-compose exec cli composer install"
  echo "docker-compose exec cli drush si demo_umami -y"
  echo "docker-compose exec cli drush la"
  echo "docker-compose exec cli drush sql-sync @self @lagoon.[project]-[env]"
  echo "docker-compose exec cli drush rsync @self:%files @lagoon.[project]-[env]:%files"

  }

# Execute the main function
main
