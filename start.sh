#!/bin/bash

echo "Starting StackPilot... Version 0.1.4"

# Prevent storing sensitive commands in bash history
export HISTIGNORE='doppler*:gh auth*'

# Initialize variables with default values. These variables are used to store the values of the command-line arguments.
RELOAD="false"
DEBUG="false"
SYSTEM_PREP="true"
AUTH_CONFIG="true"
ENVIRONMENT="prd"
GITHUB_TOKEN=""
DOPPLER_TOKEN=""
DOPPLER_PROJECT=""
DOPPLER_CONFIG=""

STACK=""

NODE_VERSION=""
BUN_VERSION=""
PYTHON_VERSION=""

# All functions are defined below.

# Function to display usage instructions and exit. This function is called when the user provides invalid arguments or when the user provides the --help flag or the -h flag.
usage_instructions() {
  echo "Usage Instructions: $0 [OPTIONS]"
  echo "Required Options:"
  echo "  --github-token TOKEN          GitHub token for authentication"
  echo "  --doppler-token TOKEN         Doppler token for secure secrets access"
  echo "  --doppler-project PROJECT     Doppler project to use"
  echo "  --doppler-config CONFIG       Doppler config to use"
  echo "  --stack STACK                 Specify the technology stack as 'node', 'bun', or 'python'"
  echo "  or"
  echo "  --node-version VERSION        Version of Node.js to install"
  echo "  --bun-version VERSION         Version of Bun to install"
  echo "  --python-version VERSION      Version of Python to install"
  echo ""
  echo "Optional Options:"
  echo "  --debug                       Enable debug mode for verbose logging"
  echo "  --no-sysprep                  Skip system preparation"
  echo "  --no-auth                     Skip authentication setup"
  echo "  --dev                         Set environment to development (default is production)"
  echo ""
  echo "Examples with curl:"
  echo " curl -sL sh.stackpilot.xyz | bash -s -- --github-token TOKEN --doppler-token TOKEN --doppler-project PROJECT --doppler-config CONFIG --stack node"
  echo " or"
  echo " curl -sL sh.stackpilot.xyz | bash -s -- --github-token TOKEN --doppler-token TOKEN --doppler-project PROJECT --doppler-config CONFIG --node-version VERSION"
}

# Function to parse the command-line arguments. It processes the command-line arguments and sets the corresponding variables.
parse_arguments() {
  # Process command-line arguments in a loop to set the corresponding variables.
  while [[ "$#" -gt 0 ]]; do
    case $1 in
    --help | -h)
      usage_instructions
      ;;
    --reload)
      RELOAD="true"
      ;;
    --debug)
      DEBUG="true"
      ;;
    --no-sysprep)
      SYSTEM_PREP="false"
      ;;
    --no-auth)
      AUTH_CONFIG="false"
      ;;
    --dev)
      ENVIRONMENT="dev"
      ;;
    --github-token)
      if [ -n "$2" ] && [[ $2 != --* ]]; then
        GITHUB_TOKEN="$2"
        shift
      else
        echo "Error: Argument for $1 is missing" >&2
        exit 1
      fi
      ;;
    --doppler-token)
      if [ -n "$2" ] && [[ $2 != --* ]]; then
        DOPPLER_TOKEN="$2"
        shift
      else
        echo "Error: Argument for $1 is missing" >&2
        exit 1
      fi
      ;;
    --doppler-project)
      if [ -n "$2" ] && [[ $2 != --* ]]; then
        DOPPLER_PROJECT="$2"
        shift
      else
        echo "Error: Argument for $1 is missing" >&2
        exit 1
      fi
      ;;
    --doppler-config)
      if [ -n "$2" ] && [[ $2 != --* ]]; then
        DOPPLER_CONFIG="$2"
        shift
      else
        echo "Error: Argument for $1 is missing" >&2
        exit 1
      fi
      ;;
    --node-version | --bun-version | --python-version)
      if [[ $2 =~ ^[0-9]+(\.[0-9]+)*$ ]]; then
        if [[ $1 == "--node-version" ]]; then
          NODE_VERSION="$2"
          STACK="node"
        elif [[ $1 == "--bun-version" ]]; then
          BUN_VERSION="$2"
          STACK="bun"
        elif [[ $1 == "--python-version" ]]; then
          PYTHON_VERSION="$2"
          STACK="python"
        fi
        shift
      else
        echo "Error: Invalid version number for $1. Only numeric values like 1 or 1.2.6 are accepted." >&2
        exit 1
      fi
      ;;
    --stack)
      if [ -n "$2" ] && { [ "$2" = "node" ] || [ "$2" = "bun" ] || [ "$2" = "python" ]; }; then
        STACK="$2"
        shift
      else
        echo "Error: Invalid or missing argument for $1. Valid options are 'node', 'bun', or 'python'" >&2
        exit 1
      fi
      ;;
    *)
      if [ -z "$STACK" ]; then
        echo "Error: --stack is mandatory if no version argument is provided" >&2
        exit 1
      else
        echo "Unrecognized argument: $1" >&2
        exit 1
      fi
      ;;
    esac
    shift
  done

  # Print the values of the variables if debug mode is enabled.
  if [ "$DEBUG" = "true" ]; then
    echo "DEBUG: $DEBUG"
    echo "SYSTEM_PREP: $SYSTEM_PREP"
    echo "AUTH_CONFIG: $AUTH_CONFIG"
    echo "ENVIRONMENT: $ENVIRONMENT"
    echo "GITHUB_TOKEN: $GITHUB_TOKEN"
    echo "DOPPLER_TOKEN: $DOPPLER_TOKEN"
    echo "DOPPLER_PROJECT: $DOPPLER_PROJECT"
    echo "DOPPLER_CONFIG: $DOPPLER_CONFIG"
    echo "STACK: $STACK"
    echo "NODE_VERSION: $NODE_VERSION"
    echo "BUN_VERSION: $BUN_VERSION"
    echo "PYTHON_VERSION: $PYTHON_VERSION"
  fi
}

# Check if all required arguments are provided and if not, echo an error message with the missing arguments and usage instructions, then exit.
check_required_args() {
  local missing_args=()
  local stack_specified=false

  # Check for individual required arguments
  [[ -z "$GITHUB_TOKEN" ]] && missing_args+=("--github-token TOKEN")
  [[ -z "$DOPPLER_TOKEN" ]] && missing_args+=("--doppler-token TOKEN")
  [[ -z "$DOPPLER_PROJECT" ]] && missing_args+=("--doppler-project PROJECT")
  [[ -z "$DOPPLER_CONFIG" ]] && missing_args+=("--doppler-config CONFIG")

  # Check for stack specification either by --stack or a specific version
  if [[ -n "$STACK" ]] || [[ -n "$NODE_VERSION" ]] || [[ -n "$BUN_VERSION" ]] || [[ -n "$PYTHON_VERSION" ]]; then
    stack_specified=true
  fi

  if ! $stack_specified; then
    missing_args+=("either --stack STACK or one of --node-version VERSION, --bun-version VERSION, --python-version VERSION")
  fi

  # If there are missing arguments, display the error message and usage instructions
  if ((${#missing_args[@]} > 0)); then
    echo -e "\e[31mError! Missing required arguments:\e[0m"
    for arg in "${missing_args[@]}"; do
      echo "  $arg"
    done
    echo ""
    usage_instructions
    echo ""
    exit 1
  fi
}

download_reload_shell_script() {
  if ! curl -o reload_shell.sh https://raw.githubusercontent.com/vivekrp/stackpilot/main/reload_shell.sh; then
    wget -O reload_shell.sh https://raw.githubusercontent.com/vivekrp/stackpilot/main/reload_shell.sh
  fi
}

# Function to add a path to the appropriate profile files
add_to_path() {
  local path_to_add="$1"
  local profile_files=("$HOME/.bash_profile" "$HOME/.bashrc" "$HOME/.profile" "$HOME/.zshrc")

  for profile_file in "${profile_files[@]}"; do
    if [ -f "$profile_file" ]; then
      # Append only if the line does not exist
      if ! grep -qxF "export PATH=\"$path_to_add:\$PATH\"" "$profile_file"; then
        echo ""
        echo -e "\n# Add $path_to_add to PATH" >>"$profile_file"
        echo "export PATH=\"$path_to_add:\$PATH\"" >>"$profile_file"
      fi
    fi
  done
}

# Function to source profile files
source_profiles() {
  local profile_files=("$HOME/.bash_profile" "$HOME/.bashrc" "$HOME/.profile" "$HOME/.zshrc")
  for profile_file in "${profile_files[@]}"; do
    if [ -f "$profile_file" ]; then
      # shellcheck disable=SC1090
      source "$profile_file"
    fi
  done
}

# Function to execute the system_prep.sh script.
system_prep() {
  curl -sL https://raw.githubusercontent.com/vivekrp/stackpilot/main/system_prep.sh | bash
}

# Function to execute the auth_config.sh script.
auth_config() {
  # Execute setup function with the environment variables
  export GITHUB_TOKEN="$GITHUB_TOKEN"
  export DOPPLER_TOKEN="$DOPPLER_TOKEN"
  export DOPPLER_PROJECT="$DOPPLER_PROJECT"
  export DOPPLER_CONFIG="$DOPPLER_CONFIG"
  curl -sL https://raw.githubusercontent.com/vivekrp/stackpilot/main/auth_config.sh | bash
}

# Function to execute the install_bun.sh script.
install_bun() {
  # Execute install function with the environment variables
  export BUN_VERSION="$BUN_VERSION"
  curl -sL https://raw.githubusercontent.com/vivekrp/stackpilot/main/install_bun.sh | bash
}

# Function to execute the install_node.sh script.
install_node() {
  # Execute install function with the environment variables
  export NODE_VERSION="$NODE_VERSION"
  curl -sL https://raw.githubusercontent.com/vivekrp/stackpilot/main/install_node.sh | bash
}

# Function to execute the install_python.sh script.
install_python() {
  # Execute install function with the environment variables
  export PYTHON_VERSION="$PYTHON_VERSION"
  curl -sL https://raw.githubusercontent.com/vivekrp/stackpilot/main/install_python.sh | bash
}

# Function to execute the end.sh script.
end() {
  curl -sL https://raw.githubusercontent.com/vivekrp/stackpilot/main/end.sh | bash
}

# Export the functions to the current shell session for use in other shell scripts and functions.
export -f download_reload_shell_script add_to_path source_profiles system_prep auth_config install_bun install_node install_python end

# Call the functions
parse_arguments "$@"
check_required_args "$@"

# By default don't execute the download_reload_shell_script function, only execute it if --reload argument is provided
if [ "$RELOAD" == "true" ]; then
  download_reload_shell_script
fi

# By default, execute the system_prep function. If --no-system-prep is provided, skip it.
if [ "$SYSTEM_PREP" == "true" ]; then
  system_prep
elif [ "$SYSTEM_PREP" == "false" ]; then
  echo "Skipping system_prep function as per the environment variable."
else
  echo "No valid system_prep environment variable provided. Set SYSTEM_PREP to 'yes' to execute system_prep or 'no' to skip it."
  exit 1
fi

# Detect the stack & call the appropriate function
if [ "$STACK" == "bun" ]; then
  install_bun
elif [ "$STACK" == "node" ]; then
  install_node
elif [ "$STACK" == "python" ]; then
  install_python
else
  echo "No valid stack detected. Set STACK to 'bun', 'node', or 'python' to execute the appropriate function."
  exit 1
fi

# By default, execute the auth_config function. If --no-auth-config is provided, skip it.
if [ "$AUTH_CONFIG" == "true" ]; then
  auth_config
elif [ "$AUTH_CONFIG" == "false" ]; then
  echo "Skipping auth_config function as per the environment variable."
else
  echo "No valid auth_config environment variable provided. Set AUTH_CONFIG to 'yes' to execute auth_config or 'no' to skip it."
  exit 1
fi

# Run the configure_shell function
# configure_shell

# end function
end
