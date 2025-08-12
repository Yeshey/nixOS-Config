# nvidia-vgpu-autostart.nix
# way to fucking complex but it works, set up mdevctl devices on startup, done by calude
# check sudo mdevctl list -d
{ config, lib, pkgs, ... }:

{
  ##############################################################################
  # 1. One-shot script that creates/starts the vGPUs with proper checks
  ##############################################################################
  systemd.services.create-vgpu-mdevs = {
    description = "Create NVIDIA vGPU mediated devices";
    path = with pkgs; [ mdevctl gawk coreutils ];
    
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "root";
      # Add timeout and restart policy for robustness
      TimeoutStartSec = 300;
      Restart = "on-failure";
      RestartSec = 10;
      
      ExecStart = pkgs.writeShellScript "create-vgpu-mdevs.sh" ''
        set -euo pipefail
        
        echo "Waiting for NVIDIA vGPU infrastructure to be ready..."
        
        # Wait for the mdev_supported_types directory to appear
        # This indicates the NVIDIA driver has fully initialized vGPU support
        max_wait=60
        wait_time=0
        while [ ! -d "/sys/bus/pci/devices/0000:01:00.0/mdev_supported_types" ] && [ $wait_time -lt $max_wait ]; do
          echo "Waiting for vGPU support... ($wait_time/$max_wait seconds)"
          sleep 2
          wait_time=$((wait_time + 2))
        done
        
        if [ ! -d "/sys/bus/pci/devices/0000:01:00.0/mdev_supported_types" ]; then
          echo "ERROR: vGPU support not available after $max_wait seconds"
          exit 1
        fi
        
        # Verify the specific vGPU type exists
        if [ ! -d "/sys/bus/pci/devices/0000:01:00.0/mdev_supported_types/nvidia-333" ]; then
          echo "ERROR: nvidia-333 vGPU type not found"
          echo "Available types:"
          ls -la "/sys/bus/pci/devices/0000:01:00.0/mdev_supported_types/" || true
          exit 1
        fi
        
        echo "Creating vGPU mediated devices..."
        for uuid in ce851576-7e81-46f1-96e1-718da691e53e \
                    b761f485-1eac-44bc-8ae6-2a3569881a1a; do
          echo "Processing UUID: $uuid"
          
          # Clean up any existing instances
          mdevctl stop --uuid "$uuid" 2>/dev/null || true
          mdevctl undefine --uuid "$uuid" 2>/dev/null || true
          
          # Create and start the vGPU
          echo "Creating vGPU with UUID $uuid"
          mdevctl start -u "$uuid" -p 0000:01:00.0 --type nvidia-333
          
          # Make it persistent
          echo "Making vGPU $uuid persistent"
          mdevctl define --auto --uuid "$uuid"
        done
        
        # Set up Looking Glass shared memory
        echo "Setting up Looking Glass shared memory"
        touch /dev/shm/looking-glass
        chmod 777 /dev/shm/looking-glass
        
        echo "vGPU setup completed successfully"
      '';
    };
    
    # Ensure this runs after the GPU driver is loaded and initialized
    after = [ 
      "systemd-modules-load.service"
      "systemd-udev-settle.service" 
      "multi-user.target"
    ];
    wants = [ "systemd-udev-settle.service" ];
  };

  ##############################################################################
  # 2. Path unit that triggers when vGPU support is actually ready
  ##############################################################################
  systemd.paths.create-vgpu-mdevs-trigger = {
    description = "Trigger vGPU creation when vGPU support is ready";
    wantedBy = [ "multi-user.target" ];
    
    pathConfig = {
      # Wait for the mdev_supported_types directory, not just the PCI device
      PathExists = "/sys/bus/pci/devices/0000:01:00.0/mdev_supported_types";
      # Add some delay to ensure driver is fully settled
      TriggerLimitBurst = 1;
      TriggerLimitIntervalSec = 30;
    };
    
    # Make sure this path unit starts after basic system initialization
    after = [ 
      "systemd-udev-settle.service"
      "systemd-modules-load.service" 
    ];
    wants = [ "systemd-udev-settle.service" ];
  };

  # Link the trigger to the service
  systemd.services.create-vgpu-mdevs.wantedBy = 
    lib.mkForce [ "create-vgpu-mdevs-trigger.path" ];

  ##############################################################################
  # 3. Optional: Add a timer-based fallback in case path unit doesn't trigger
  ##############################################################################
  systemd.timers.create-vgpu-mdevs-fallback = {
    description = "Fallback timer for vGPU creation";
    wantedBy = [ "timers.target" ];
    
    timerConfig = {
      # Try once 2 minutes after boot
      OnBootSec = "2min";
      # Don't repeat - this is just a fallback
      Persistent = false;
    };
    
    after = [ "multi-user.target" ];
  };
  
  # Create a separate fallback service that only runs if the main service hasn't succeeded
  systemd.services.create-vgpu-mdevs-fallback = {
    description = "Fallback vGPU creation service";
    
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      
      ExecStart = pkgs.writeShellScript "vgpu-fallback.sh" ''
        set -euo pipefail
        
        # Check if the main service already succeeded
        if systemctl is-active --quiet create-vgpu-mdevs.service; then
          echo "Main vGPU service already active, skipping fallback"
          exit 0
        fi
        
        echo "Main vGPU service not active, attempting fallback creation"
        systemctl start create-vgpu-mdevs.service || {
          echo "Fallback vGPU creation failed"
          exit 1
        }
      '';
    };
  };
  
  # Link the fallback timer to the fallback service
  systemd.services.create-vgpu-mdevs-fallback.wantedBy = 
    [ "create-vgpu-mdevs-fallback.timer" ];
}