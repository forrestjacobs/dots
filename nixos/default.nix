{ config, lib, pkgs, ... }: {

  imports = [
    ./forrest.nix
    ./impermanence.nix
    ./update.nix
  ];

  boot.loader.systemd-boot.netbootxyz.enable = true;

  environment = {
    defaultPackages = lib.mkForce [ ];
    shellAliases = lib.mkForce { };
    systemPackages = [
      pkgs.git
      pkgs.unstable.helix
      pkgs.nano
      pkgs.wget # required by VS Code WSL plugin -- who knew??
    ];
  };

  nix = {
    settings = {
      allowed-users = [ "@wheel" ];
      auto-optimise-store = true;
      experimental-features = [ "nix-command" "flakes" ];
    };
    gc = {
      automatic = true;
      persistent = false;
      options = "--delete-older-than 14d";
    };
  };

  programs = {
    command-not-found.enable = false;
    fish = {
      enable = true;
      shellInit = ''
        set -gx EDITOR hx
      '';
    };
    mosh.enable = lib.mkDefault config.services.openssh.enable;
  };

  security.sudo = {
    execWheelOnly = true;
    wheelNeedsPassword = false;
  };

  services.fstrim.enable = lib.mkDefault true;

  services.openssh = {
    settings.PasswordAuthentication = false;
    settings.PermitRootLogin = "no";
    ports = [ 36522 ];
  };

  system.stateVersion = lib.mkDefault "22.05";

  systemd.services.fetch-dots = {
    description = "Fetch dot updates";
    startAt = "hourly";
    path = [ pkgs.openssh ];
    serviceConfig = {
      Type = "oneshot";
      User = "forrest";
      WorkingDirectory = "/etc/nixos";
      ExecStart = "${pkgs.git}/bin/git fetch";
    };
  };

  time.timeZone = "America/New_York";

  users.defaultUserShell = pkgs.fish;

  virtualisation.docker.autoPrune.enable = true;

}
