#!/bin/bash

# ==============================================================================
# Script: provision_azure_user.sh
# Description: This script automates the creation of a new Azure AD user
#              and assigns them a role based on a predefined template.
#
# Usage: ./provision_azure_user.sh -d "Display Name" -u "user.name" -t "role_template"
#
# Arguments:
#   -d, --display-name  The display name for the new user (e.g., "John Doe").
#   -u, --user-principal-name The User Principal Name (UPN) for the new user
#                             (e.g., "johndoe@yourdomain.com").
#   -t, --template      The role template to use (e.g., "developer", "reader").
#
# Prerequisites:
#   - Azure CLI installed and configured.
#   - Logged in to Azure with `az login`.
#   - Appropriate permissions to create users and assign roles in Azure AD.
#
# ==============================================================================

# --- Configuration ---

# Set to "true" to enable debug mode, which prints more verbose output.
DEBUG=false

# --- Helper Functions ---

# Function to print log messages.
# Usage: log "Your message here"
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] - $1"
}

# Function to print error messages and exit.
# Usage: error_exit "Your error message here"
error_exit() {
    log "ERROR: $1" >&2
    exit 1
}

# Function to display the script's usage instructions.
usage() {
    echo "Usage: $0 -d \"Display Name\" -u \"user.principal.name\" -t \"template\""
    echo "Options:"
    echo "  -d, --display-name          The display name for the new user."
    echo "  -u, --user-principal-name   The User Principal Name (UPN)."
    echo "  -t, --template              The role template (e.g., developer, reader)."
    echo "  -h, --help                  Display this help message."
    exit 1
}

# --- Argument Parsing ---

# Parse command-line arguments.
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -d|--display-name) DISPLAY_NAME="$2"; shift ;;
        -u|--user-principal-name) UPN="$2"; shift ;;
        -t|--template) TEMPLATE="$2"; shift ;;
        -h|--help) usage ;;
        *) error_exit "Unknown parameter passed: $1";;
    esac
    shift
done

# Validate that all required arguments are provided.
if [ -z "$DISPLAY_NAME" ] || [ -z "$UPN" ] || [ -z "$TEMPLATE" ]; then
    log "Missing required arguments."
    usage
fi

# --- Main Logic ---

# Function to create the Azure AD user.
create_user() {
    log "Starting user creation process for UPN: $UPN"

    # For security, we'll generate a random password.
    # The user will be forced to change it on first login.
    PASSWORD=$(openssl rand -base64 12)
    if [ $? -ne 0 ]; then
        error_exit "Failed to generate a random password."
    fi

    log "Creating user with Display Name: '$DISPLAY_NAME' and UPN: '$UPN'."

    # The `az ad user create` command creates the user in Azure Active Directory.
    USER_OBJECT_ID=$(az ad user create \
        --display-name "$DISPLAY_NAME" \
        --user-principal-name "$UPN" \
        --password "$PASSWORD" \
        --force-change-password-next-sign-in \
        --query "id" \
        -o tsv)

    if [ -z "$USER_OBJECT_ID" ]; then
        error_exit "Failed to create user '$UPN'. The command returned no object ID."
    fi

    log "Successfully created user '$UPN'. Object ID: $USER_OBJECT_ID"
    log "Initial Password: $PASSWORD"
    echo "------------------------------------------------------------------"
    echo "IMPORTANT: Please securely provide the following temporary password to the user."
    echo "Username: $UPN"
    echo "Temporary Password: $PASSWORD"
    echo "The user will be required to change this password upon first login."
    echo "------------------------------------------------------------------"
}

# Function to assign a role to the user based on the template.
assign_role() {
    log "Starting role assignment for user '$UPN' with template '$TEMPLATE'."

    local role_name=""

    # --- Role Template Definitions ---
    # Add more templates here as needed.
    case "$TEMPLATE" in
        "developer")
            role_name="Contributor"
            ;;
        "reader")
            role_name="Reader"
            ;;
        "owner")
            role_name="Owner"
            ;;
        *)
            error_exit "Invalid template '$TEMPLATE'. Available templates: developer, reader, owner."
            ;;
    esac

    log "Mapping template '$TEMPLATE' to role '$role_name'."

    # Get the ID of the current subscription.
    # Roles are assigned within a scope, such as a subscription or resource group.
    # For this script, we'll use the current subscription as the scope.
    SUBSCRIPTION_ID=$(az account show --query "id" -o tsv)
    if [ -z "$SUBSCRIPTION_ID" ]; then
        error_exit "Could not determine the current subscription ID. Are you logged in?"
    fi
    SCOPE="/subscriptions/$SUBSCRIPTION_ID"

    log "Assigning role '$role_name' to user '$UPN' at scope '$SCOPE'."

    # The `az role assignment create` command assigns the specified role to the user.
    az role assignment create \
        --assignee-object-id "$USER_OBJECT_ID" \
        --assignee-principal-type "User" \
        --role "$role_name" \
        --scope "$SCOPE"

    if [ $? -ne 0 ]; then
        error_exit "Failed to assign role '$role_name' to user '$UPN'."
    fi

    log "Successfully assigned role '$role_name' to user '$UPN'."
}

# --- Script Execution ---

log "Azure User Provisioning Script started."

# Check if logged into Azure
if ! az account show > /dev/null 2>&1; then
    error_exit "You are not logged into Azure. Please run 'az login' first."
fi

create_user
assign_role

log "Script finished successfully."
exit 0
