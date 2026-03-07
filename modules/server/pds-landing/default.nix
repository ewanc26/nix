{
  lib,
  stdenv,
  path ? ./.,
}:

stdenv.mkDerivation {
  pname = "pds-landing";
  version = "1.0.0";

  src = path;

  # Unpack the source, then copy everything to output
  phases = [
    "unpackPhase"
    "installPhase"
  ];

  installPhase = ''
    mkdir -p $out
    # Copy all files from the unpacked source
    cp -r . $out/
    # Remove .DS_Store files if present
    find $out -name ".DS_Store" -delete
  '';

  meta = with lib; {
    description = "Ewan's personal PDS (Personal Data Server) landing page";
    homepage = "https://pds.ewancroft.uk";
    license = licenses.agpl3Only;
    platforms = platforms.all;
  };
}
