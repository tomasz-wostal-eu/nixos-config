final: prev:
let
  # fabric 3.2.3 pins invoke<3.0, nixpkgs ships invoke 3.0.3 and the
  # runtime deps check fails. Relax the pin; its test suite mocks invoke
  # internals that changed in 3.x, so skip it too.
  fabricFix = pyfinal: pyprev: {
    fabric = pyprev.fabric.overridePythonAttrs (old: {
      pythonRelaxDeps = (old.pythonRelaxDeps or [ ]) ++ [ "invoke" ];
      doCheck = false;
    });
  };

  # azure-cli builds its own interpreter via `python3.override { packageOverrides = ...; }`,
  # which replaces any packageOverrides set from outside. Hand it a python3
  # whose override composes our fix in.
  python3 = prev.python3 // {
    override = args:
      prev.python3.override (args // {
        packageOverrides =
          prev.lib.composeExtensions fabricFix (args.packageOverrides or (_: _: { }));
      });
  };
in
{
  azure-cli = prev.azure-cli.override { inherit python3; };
}
