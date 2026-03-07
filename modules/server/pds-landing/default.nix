{
  lib,
  stdenv,
}:

let
  # Explicitly reference the landing page files
  sourceFiles = lib.sourceByRegex ./. [
    "^(index\.html|script\.js|status\.js|utils\.js)$"
    "^styles(/.*)?$"
    "^assets(/.*)?$"
  ];
in
stdenv.mkDerivation {
  pname = "pds-landing";
  version = "1.0.0";

  src = sourceFiles;

  phases = [
    "unpackPhase"
    "installPhase"
  ];

  installPhase = ''
    mkdir -p $out
    cp -r . $out/
  '';

  meta = with lib; {
    description = "Ewan's personal PDS (Personal Data Server) landing page";
    homepage = "https://pds.ewancroft.uk";
    license = licenses.agpl3Only;
    platforms = platforms.all;
  };
}
