{ config, pkgs, lib, ... }:

let
  customKernel = pkgs.linux_6_6.override {
    structuredExtraConfig = with lib.kernel; {
      DRM_I915_PXP = yes;
      INTEL_MEI_PXP = module;
    };
  };

  customKernelPackages = pkgs.linuxPackagesFor customKernel;

  i915SRIOVModule = customKernelPackages.callPackage ({ stdenv, kernel }:
    stdenv.mkDerivation {
      pname = "i915-sriov-dkms";
      version = "2024.08.09";

      src = pkgs.fetchFromGitHub {
        owner = "strongtz";
        repo = "i915-sriov-dkms";
        rev = "master";
        sha256 = "sha256-JmGBVfXlxqCommGXVSx8ecz+1e/VC0Crc+4PadQHJsI=";  # Replace with the correct hash
      };

      nativeBuildInputs = kernel.moduleBuildDependencies ++ [ pkgs.xz ];

      makeFlags = [
        "KERNELRELEASE=${kernel.modDirVersion}"
        "KERNEL_DIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
      ];

      buildPhase = ''
        make -C ${kernel.dev}/lib/modules/${kernel.modDirVersion}/build \
          M=$(pwd) \
          KERNELRELEASE=${kernel.modDirVersion}
      '';


      installPhase = ''
        mkdir -p $out/lib/modules/${kernel.modDirVersion}/extra
        ${pkgs.xz}/bin/xz -z -f i915.ko
        cp i915.ko.xz $out/lib/modules/${kernel.modDirVersion}/extra/i915-sriov.ko.xz
      '';


      meta = with lib; {
        description = "Custom module for i915 SRIOV support";
        homepage = "https://github.com/strongtz/i915-sriov-dkms";
        license = licenses.gpl2Only;
        platforms = platforms.linux;
      };
    }
  ) {};

in {
  boot.kernelPackages = customKernelPackages;
  boot.extraModulePackages = [ i915SRIOVModule ];

  # Blacklist the stock i915 module
  boot.blacklistedKernelModules = [ "i915" ];


  # Ensure our custom i915 module and mei_pxp are loaded
  boot.kernelModules = [ "i915-sriov" "mei_pxp" ];
  boot.initrd.kernelModules = [ "i915-sriov" ];

    # Set up module loading order and options
  boot.extraModprobeConfig = ''
    alias i915 i915-sriov
    options i915-sriov  enable_guc=3 max_vfs=7
    softdep i915-sriov post: mei_pxp
  '';

   # Rebuild module dependencies after boot
  boot.postBootCommands = ''
    /run/current-system/sw/bin/depmod -a ${customKernel.modDirVersion}
  '';

}

