#!/bin/bash
# Script to update Ansible hosts file with current IPs from Vagrant
# This bypasses the need for Ansible to connect when IPs are wrong

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOSTS_FILE="${SCRIPT_DIR}/hosts"
TEMP_FILE=$(mktemp)

# Check if vagrant is available
if ! command -v vagrant &> /dev/null; then
    echo "Error: vagrant command not found"
    exit 1
fi

# Check if we're in a vagrant directory
if [ ! -f "${SCRIPT_DIR}/Vagrantfile" ]; then
    echo "Error: Vagrantfile not found in ${SCRIPT_DIR}"
    exit 1
fi

cd "${SCRIPT_DIR}"

# Get SSH config from vagrant
echo "Getting current IP addresses from Vagrant..."
VAGRANT_SSH_CONFIG=$(vagrant ssh-config 2>/dev/null)

if [ -z "$VAGRANT_SSH_CONFIG" ]; then
    echo "Error: Could not get SSH config from Vagrant. Are the VMs running?"
    echo "Run 'vagrant status' to check VM status"
    exit 1
fi

# Function to extract IP from ssh-config for a hostname
get_ip_for_host() {
    local hostname=$1
    echo "$VAGRANT_SSH_CONFIG" | awk -v host="$hostname" '
        BEGIN { current_host = ""; found = 0 }
        /^Host / { 
            current_host = $2
            if (current_host == host) found = 1
            else found = 0
        }
        found && /^[[:space:]]*HostName / { 
            # Remove quotes if present
            gsub(/^["'\'']|["'\'']$/, "", $2)
            print $2
            exit
        }
    '
}

# Function to get private key path from ssh-config for a hostname
get_key_for_host() {
    local hostname=$1
    echo "$VAGRANT_SSH_CONFIG" | awk -v host="$hostname" '
        BEGIN { current_host = ""; found = 0 }
        /^Host / { 
            current_host = $2
            if (current_host == host) found = 1
            else found = 0
        }
        found && /^[[:space:]]*IdentityFile / { 
            # Remove quotes if present
            gsub(/^["'\'']|["'\'']$/, "", $2)
            print $2
            exit
        }
    '
}

# Start building the hosts file
cat > "$TEMP_FILE" << 'EOF'
[head]
EOF

# Get head IP and key
HEAD_IP=$(get_ip_for_host "head")
HEAD_KEY=$(get_key_for_host "head")

if [ -z "$HEAD_IP" ]; then
    echo "Warning: Could not find IP for head"
else
    # Convert absolute path to relative if it's in the project directory
    if [[ "$HEAD_KEY" == "$SCRIPT_DIR"* ]]; then
        HEAD_KEY="${HEAD_KEY#$SCRIPT_DIR}"
        HEAD_KEY="${HEAD_KEY#/}"  # Remove leading slash if present
    fi
    echo "head ansible_host=${HEAD_IP} ansible_user=vagrant ansible_ssh_private_key_file=${HEAD_KEY}" >> "$TEMP_FILE"
fi

echo "" >> "$TEMP_FILE"
echo "[compute]" >> "$TEMP_FILE"

# Get compute node IPs and keys
for compute_host in compute1 compute2; do
    COMPUTE_IP=$(get_ip_for_host "$compute_host")
    COMPUTE_KEY=$(get_key_for_host "$compute_host")
    
    if [ -z "$COMPUTE_IP" ]; then
        echo "Warning: Could not find IP for $compute_host"
    else
        # Convert absolute path to relative if it's in the project directory
        if [[ "$COMPUTE_KEY" == "$SCRIPT_DIR"* ]]; then
            COMPUTE_KEY="${COMPUTE_KEY#$SCRIPT_DIR}"
            COMPUTE_KEY="${COMPUTE_KEY#/}"  # Remove leading slash if present
        fi
        echo "${compute_host} ansible_host=${COMPUTE_IP} ansible_user=vagrant ansible_ssh_private_key_file=${COMPUTE_KEY}" >> "$TEMP_FILE"
    fi
done


# Replace the hosts file
mv "$TEMP_FILE" "$HOSTS_FILE"

echo ""
echo "Successfully updated ${HOSTS_FILE} with current IP addresses:"
echo ""
cat "$HOSTS_FILE"
echo ""
