final: prev:
let
  # marimo 0.25.1 pins uv_build<0.13.0 in its build-system requirements, but
  # the pinned nixpkgs ships uv-build 0.13.x. Drop the version bound; remove
  # this overlay once nixpkgs carries a marimo that accepts the newer uv-build.
  marimoOverrides = pyfinal: pyprev: {
    marimo = pyprev.marimo.overridePythonAttrs (old: {
      postPatch = (old.postPatch or "") + ''
        sed -i -E 's/"uv_build[^"]*"/"uv_build"/' pyproject.toml
      '';
    });
  };
in
{
  python314 = prev.python314.override (old: {
    self = final.python314;
    packageOverrides =
      prev.lib.composeExtensions (old.packageOverrides or (_: _: { })) marimoOverrides;
  });
}
