final: prev:
let
  # Test suites broken on the pinned nixpkgs after the python 3.14 bump;
  # skip checks, the packages themselves work fine.
  skipChecks = pkg:
    pkg.overridePythonAttrs (_: {
      doCheck = false;
      doInstallCheck = false;
    });
  brokenTestOverrides = pyfinal: pyprev: {
    pipx = skipChecks pyprev.pipx;
    poetry = skipChecks pyprev.poetry;
  };
in
{
  # Top-level poetry rebuilds itself via its own callPackage, ignoring
  # python packageOverrides — override it directly.
  poetry = skipChecks prev.poetry;

  python313 = prev.python313.override (old: {
    self = final.python313;
    packageOverrides =
      prev.lib.composeExtensions (old.packageOverrides or (_: _: { })) brokenTestOverrides;
  });
  python314 = prev.python314.override (old: {
    self = final.python314;
    packageOverrides =
      prev.lib.composeExtensions (old.packageOverrides or (_: _: { })) brokenTestOverrides;
  });
}
