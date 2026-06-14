final: prev: {
  python313 = prev.python313.override (old: {
    self = final.python313;
    packageOverrides = pyfinal: pyprev: {
      pipx = pyprev.pipx.overridePythonAttrs (_: {
        doCheck = false;
        doInstallCheck = false;
      });
    };
  });
}
