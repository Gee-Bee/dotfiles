{ lib, stdenv, jq, on-air-plasmoid }:

stdenv.mkDerivation {
  pname = "plasma-applet-on-air";
  version = on-air-plasmoid.shortRev or on-air-plasmoid.rev or "unstable";
  src = on-air-plasmoid;
  nativeBuildInputs = [ jq ];
  dontConfigure = true;
  dontBuild = true;
  installPhase = ''
    runHook preInstall
    metadataFile=$(find . -maxdepth 3 -name metadata.json | head -n1)
    pkgDir=$(dirname "$metadataFile")
    pluginId=$(jq -r '.KPlugin.Id' "$metadataFile")
    mkdir -p "$out/share/plasma/plasmoids/$pluginId"
    cp -r "$pkgDir"/. "$out/share/plasma/plasmoids/$pluginId"/
    runHook postInstall
  '';
  meta = with lib; {
    description = "On Air – internet radio widget for KDE Plasma 6";
    homepage = "https://github.com/Mendior/on-air-plasmoid";
    license = licenses.lgpl2Plus;
    platforms = platforms.linux;
  };
}