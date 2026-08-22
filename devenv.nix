{
  pkgs,
  lib,
  config,
  ...
}:
let
  playwrightLibs = with pkgs; [
    alsa-lib
    atk
    cairo
    dbus
    fontconfig
    freetype
    gdk-pixbuf
    glib
    gtk3
    pango
    libX11
    libXcomposite
    libXcursor
    libXdamage
    libXext
    libXfixes
    libXi
    libXrandr
    libXrender
    libxcb
  ];
in
{
  packages = [
    pkgs.git
    pkgs.git-absorb
    pkgs.sops
    pkgs.age
  ] ++ playwrightLibs;

  env.LD_LIBRARY_PATH = lib.makeLibraryPath playwrightLibs;

  # https://devenv.sh/languages/
  languages.python = {
    enable = true;
    version = "3.14";
    venv.enable = true;
    uv.enable = true;
    uv.sync.enable = true;
  };

  dotenv.disableHint = true;

  # See full reference at https://devenv.sh/reference/options/
}
