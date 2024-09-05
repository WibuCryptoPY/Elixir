#!/bin/bash

# Check if the script is run as root user
if [ "$(id -u)" != "0" ]; then
    echo "This script needs to be run with root user privileges."
    echo "Please try using 'sudo -i' to switch to the root user, and then run this script again."
    exit 1
fi

# Script save path
SCRIPT_PATH="$HOME/ElixirV3.sh"

# Check and install Docker
function check_and_install_docker() {
    if ! command -v docker &> /dev/null; then
        echo "Docker not detected, installing..."
        sudo apt-get update
        sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
        sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
        sudo apt-get update
        sudo apt-get install -y docker-ce
        echo "Docker installed."
    else
        echo "Docker is already installed."
    fi
}

# Node installation function
function install_node() {
    check_and_install_docker

    # Prompt user to input environment variable values
    read -p "Please enter the display name of the validator node: " validator_name
    read -p "Please enter the reward collection address of the validator node: " safe_public_address
    read -p "Please enter the signer's private key, without 0x: " private_key

    # Save environment variables to the validator.env file
    cat <<EOF > validator.env
ENV=testnet-3

STRATEGY_EXECUTOR_DISPLAY_NAME=${validator_name}
STRATEGY_EXECUTOR_BENEFICIARY=${safe_public_address}
SIGNER_PRIVATE_KEY=${private_key}
EOF

    echo "Environment variables set and saved to validator.env file."

    # Pull Docker image
    docker pull elixirprotocol/validator:v3

    # Prompt user to choose platform
    read -p "Are you running on Apple/ARM architecture? (y/n): " is_arm

    if [[ "$is_arm" == "y" ]]; then
        # Run on Apple/ARM architecture
        docker run -it -d \
          --env-file validator.env \
          --name elixir \
          --platform linux/amd64 \
          elixirprotocol/validator:v3
    else
        # Default run
        docker run -it -d \
          --env-file validator.env \
          --name elixir \
          elixirprotocol/validator:v3
    fi
}

# View Docker logs function
function check_docker_logs() {
    echo "Viewing Elixir Docker container logs..."
    docker logs -f elixir
}

# Delete Docker container function
function delete_docker_container() {
    echo "Deleting Elixir Docker container..."
    docker stop elixir
    docker rm elixir
    echo "Elixir Docker container deleted."
}

# Main menu
function main_menu() {
    clear
    echo "=====================Elixir V3 Node========================="
    echo "Please choose an operation to perform:"
    echo "1. Install Elixir V3 Node"
    echo "2. View Docker Logs"
    echo "3. Delete Elixir Docker Container"
    read -p "Please enter an option (1-3): " OPTION

    case $OPTION in
    1) install_node ;;
    2) check_docker_logs ;;
    3) delete_docker_container ;;
    *) echo "Invalid option." ;;
    esac
}

# Display main menu
main_menu
