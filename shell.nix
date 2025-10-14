{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    ruby
    rubyPackages.rails
    docker
    libyaml
  ];

  shellHook = ''
    bundle install
  '';
}
