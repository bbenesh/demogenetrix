#!/bin/bash

#//TODO - store token separately and then add this script to a repo for storage, version tracking, sharing
#//TODO - lagoon user creation
#//TODO - test local spin up with docker
#//TODO - install composer req + db
#//TODO - pull all available repos from lagoon examples as options
#//TODO - push local files + db up to remote lagoon
#//TODO - Add to amazeeio-sales group + Org (when Orgs are ready)
#//TODO - Prompt for custom group
#//TODO - Add Lagoon users - create + add to project-group

# 1. Setup req's for script


  # Make sure to replace YOUR_GITHUB_TOKEN with your actual GitHub token. 
  # Also, ensure that the jq command-line JSON processor is installed on your system, 
  # as it is used to parse the response from the GitHub API.
  # brew install jq 

  # GitHub organization and token
  github_organization="amazeeio-demos"
  # Demo Creator Script Token
  github_token="<ADD TOKEN HERE>"
  

# 2. Clone repo to local

  # Define Git repository URLs
  repos=("git@github.com:lagoon-examples/drupal-base" "git@github.com:lagoon-examples/drupal9-full.git" "https://github.com/example/repo3.git")

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
  read -p "Enter a name for the directory: " dir_name

  # Clone the chosen repository into the specified directory
  git clone "${repos[$choice]}" "$dir_name"

  # Check if the clone was successful
  if [ $? -eq 0 ]; then
    echo "Repository cloned successfully into '$dir_name' directory."
  else
    echo "Failed to clone repository. Please check the repository URL and try again."
    exit 1
  fi

# 3. Rename files and replace references to old project name

  # Prompt user for string to look for and string to replace it with
  #read -p "Enter a string to look for in files: " search_string
  # read -p "Enter a string to replace it with: " replace_string

  # Extract the part of the repo string after the last /
  search_string=$(echo "${repos[$choice]}" | awk -F'/' '{print $NF}' | sed 's/\.git$//')

  # Use grep to search for the string in all files and replace it
  grep -rli "$search_string" "$dir_name" | xargs sed -i '' -e "s/$search_string/$dir_name/g"

  # Remove spaces and dashes from the original string
  modified_string=$(echo "$search_string" | tr -d '[:space:]' | tr -d '-')

  # Use grep to search for the modified string in all files and replace it
  grep -rli "$modified_string" "$dir_name" | xargs sed -i '' -e "s/$modified_string/$dir_name/g"

  echo "String '$search_string' and '$modified_string' replaced with '$dir_name' in all files."

# 4. Create a new repo, add local changes, and push up

  # Change into the newly cloned directory
  cd "$dir_name" || exit 1

  # Create a new GitHub repository using the GitHub API
  create_repo_response=$(curl -s -H "Authorization: token $github_token" -d '{"name": "'"$dir_name"'", "private": true}' "https://api.github.com/orgs/$github_organization/repos")

  # Extract the new repository URL
  new_repo_url=$(echo "$create_repo_response" | jq -r '.ssh_url')

  # Remove the old remote origin
  git remote remove origin

  # Add the new remote origin
  git remote add origin "$new_repo_url"

  # Add and commit local changes
  git add .
  git commit -m "Project init."

  # Push everything to the main branch on the new repo
  git push -u origin main

  echo "Repository '$dir_name' pushed to the new GitHub repository in the '$github_organization' organization."

# 5. Create Lagoon project
  lagoon add project -p $dir_name -b "^(main|dev|feature.*)$" -g $new_repo_url -S 126 -m true -E main

# 6. Connect Lagoon project to Git repo
  
  # Deploy Key

    # Run the 'lagoon get project-key' command and capture the output
    project_key=$(lagoon get project-key -p "$dir_name")

    # Extract the public key from the output and remove the leading "PUBLICKEY "
    public_key=$(echo "$project_key" | sed 's/PUBLICKEY //')

    # Print the extracted public key for debugging
    echo "Extracted public key: $public_key"

    # Construct the JSON data
    json_data=$(jq -n --arg title "Lagoon Deploy Key" --arg key "$public_key" --argjson read_only true '{"title": $title, "key": $key, "read_only": $read_only}')

    # Add the deploy key to the new repository using the GitHub API
    deploy_key_response=$(curl -s -H "Authorization: token $github_token" -H "Content-Type: application/json" -X POST -d "$json_data" "https://api.github.com/repos/$github_organization/$dir_name/keys" | jq '.')

    # Print the GitHub API response for debugging
    echo "GitHub API response: $deploy_key_response"

    echo "Deploy key added to the new repository in the '$github_organization' organization."


  # Webhook

  # //TODO - Fix that it's only selecting the push event

    # Construct the JSON data for the webhook
    webhook_data=$(jq -n --arg url "https://hooks.lagoon.amazeeio.cloud" '{"name": "web", "config": {"url": $url, "content_type": "json"}, "events": ["push"], "active": true}')

    # Add a webhook to the new repository using the GitHub API
    webhook_response=$(curl -s -H "Authorization: token $github_token" -H "Content-Type: application/json" -X POST -d "$webhook_data" "https://api.github.com/repos/$github_organization/$dir_name/hooks" | jq '.')

    # Print the GitHub API response for the webhook for debugging
    echo "GitHub API response (Webhook): $webhook_response"

    echo "Webhook added to the new repository in the '$github_organization' organization."

  # Trigger build
  git commit -m "Trigger build." --allow-empty
  git push origin main

# Add Lagoon project to group and/or Organization
  lagoon add project-group -p $dir_name -N amazeeio-sales

  # //TODO - Figure out Organizations

# Add users to Lagoon group
# // TODO - Lagoon add user and user-group

collect_user_info() {
  # Prompt user for email, first name, and last name
  read -p "Enter your email address: " email
  read -p "Enter your first name: " first_name
  read -p "Enter your last name: " last_name
}

add_user_to_lagoon() {
  # Assuming you have a command that takes email, first name, and last name as arguments
  echo "Running command with provided information:"
  echo "Email: $email"
  echo "First Name: $first_name"
  echo "Last Name: $last_name"
  echo "Group: project-$dir_name" 
  
  # Replace the following command with your actual command
  # Example: command_with_user_info "$email" "$first_name" "$last_name"
  lagoon add user -E "$email" -F "$first_name" -L "$last_name"
  lagoon add user-group -E "$email" -N project-$dir_name -R owner
}

# Ask the user if they want to add another user
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
  # Ask if they want to add a user
  read -p "Do you want to add a user? (yes/no): " add_user

  if [ "$add_user" = "yes" ]; then
    while true; do
      # Collect user information
      collect_user_info

      # Run a command using collected user information
      add_user_to_lagoon

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

  done
  }

# Execute the main function
main
