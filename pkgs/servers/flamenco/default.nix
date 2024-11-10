{ callPackage
, lib
, stdenv
, fetchzip
, nixos
, testers
, pkgs
, ffmpegPackage ? pkgs.ffmpeg-headless
, blenderPackage ? pkgs.blender
, flamenco
}:

with import <nixpkgs> {};
stdenv.mkDerivation (finalAttrs: {
  pname = "flamenco";
  version = "3.3";

  src = fetchzip {
    url = "https://flamenco.blender.org/downloads/flamenco-${finalAttrs.version}-linux-amd64.tar.gz";
    hash = "sha256-qd9XN7Gf882ppATZWQytCke+aCYi/I0mu1rxrLPRJE0=";
  };

  buildInputs = [ blenderPackage ffmpegPackage ];
  doCheck = true;

# TODO: add ffmpeg-linux-amd64 dependency

  passthru.tests = {
    version = testers.testVersion { package = flamenco; };
  };

  installPhase = ''
    mkdir -p $out/bin
    cp ./flamenco-{manager,worker} $out/bin/
  '';

  #passthru.tests.run = callPackage ./test.nix { flamenco = finalAttrs.finalPackage; };

  meta = with lib; {
    description = "";
    longDescription = ''
    '';
    homepage = "https://flamenco.blender.org/";
    changelog = "https://projects.blender.org/studio/flamenco/src/tag/v${finalAttrs.version}/CHANGELOG.md";
    license = licenses.gpl3Plus;
    maintainers = [ maintainers.instantepiphany ];
    # does support other platforms, not packages dyet
    platforms = platforms.linux;
  };
})
