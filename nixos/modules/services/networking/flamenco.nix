{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.flamenco;
  fhsEnvManager = pkgs.buildFHSEnv {
    name = "flamenco-manager-fhs-env";
    targetPkgs = pkgs': [ cfg.blenderPackage cfg.ffmpegPackage pkgs.flamenco "/var/lib/flamenco" ];
    extraBuildCommands = ''
      pwd
      ls
      #mkdir -p /var/lib
      #ln -s /host/var/lib/flamenco /var/lib/flamenco
      du /var/lib/flamenco/
      cp ${pkgs.flamenco}/bin/flamenco-manager /var/lib/flamenco/manager/flamenco-manager
    '';
    runScript = "ls; ./flamenco-manager";
  };
  fhsEnvWorker = pkgs.buildFHSEnv {
    name = "flamenco-worker-fhs-env";
    targetPkgs = pkgs': [ cfg.blenderPackage cfg.ffmpegPackage pkgs.flamenco ];
    runScript = "/bin/flamenco-worker";
  };
  fhsEnvManagerExecutable = "${fhsEnvManager}/bin/${fhsEnvManager.name}";
  fhsEnvWorkerExecutable = "${fhsEnvWorker}/bin/${fhsEnvWorker.name}";
in {
  options.services.flamenco = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enable the Blender render farm service (see manager and worker options).
      '';
    };

    manager = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Designate this machine as a manager of a flamenco farm.
      '';
    };

    worker = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Designate this machine as a worker within a flamenco farm.
      '';
    };

    blenderPackage = mkPackageOptionMD pkgs "blenderPackage" {
      default = [ "blender" ];
      example = "pkgs.blender";
    };
    ffmpegPackage = mkPackageOptionMD pkgs "ffmpegPackage" {
      default = [ "ffmpeg-headless" ];
      example = "pkgs.ffmpeg-headless";
    };
    #dataDir = mkOption {
    #  type = types.path;
    #  default = "/var/lib/flamenco";
    #  description = lib.mdDoc ''
    #    The directory where flamenco will create files.
    #  '';
    #};
};

  config = {
    #systemd.tmpfiles.rules = [
    #  "d '${cfg.dataDir}' 0770 flamenco flamenco"
    #];
    systemd.services.flamenco-manager = mkIf (cfg.enable)
      { description = "Flamenco manager";
        path  = [ pkgs.su cfg.blenderPackage cfg.ffmpegPackage ];
        wantedBy = mkIf (cfg.manager) [ "multi-user.target" ];
        serviceConfig = {
          DynamicUser = true;
          StateDirectory = "flamenco";
          WorkingDirectory = "/var/lib/flamenco/manager";
          Restart = "on-failure";
          ExecStart = "${fhsEnvManagerExecutable} +set fs_homepath /var/lib/flamenco/manager";
          LogLevelMax = 6;
          User = "flamenco";
          Group = "flamenco";
          # Hardening
          #CapabilityBoundingSet = "";
          #NoNewPrivileges = true;
          #PrivateDevices = true;
        };
        #script = "${pkgs.flamenco}/bin/flamenco-manager +set fs_homepath /var/lib/flamenco";
      };

    systemd.services.flamenco-worker = mkIf (cfg.enable)
      { description = "Flamenco worker";
        path  = [ pkgs.su cfg.blenderPackage cfg.ffmpegPackage ];
        wantedBy = mkIf (cfg.worker) [ "multi-user.target" ];
        serviceConfig = {
          DynamicUser = true;
          StateDirectory = "flamenco";
          WorkingDirectory = "/var/lib/flamenco/worker";
          Restart = "on-failure";
          ExecStart = "${fhsEnvWorkerExecutable} +set fs_homepath /var/lib/flamenco/worker";
          User = "flamenco";
          Group = "flamenco";
          # Hardening
          #CapabilityBoundingSet = "";
          #NoNewPrivileges = true;
          #PrivateDevices = true;
        };
        environment = {
          FLAMENCO_HOME = "/var/lib/flamenco/worker/";
        };
        #script = "${pkgs.flamenco}/bin/flamenco-worker +set fs_homepath /var/lib/flamenco";
      };
    #users.users = {
    #  flamenco = {
    #    group = cfg.group;
    #    uid = config.ids.uids.flamenco;
    #    home = cfg.dataDir;
    #    description = "flamenco user";
    #  };
    #};

    #users.groups = {
    #  flamenco = {
    #    gid = config.ids.gids.flamenco;
    #  };
    #};
  };
}
