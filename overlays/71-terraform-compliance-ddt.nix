final: prev: {
  # Its test suite imports ddt, which nixpkgs does not list as a check input.
  terraform-compliance = prev.terraform-compliance.overridePythonAttrs (old: {
    nativeCheckInputs = (old.nativeCheckInputs or [ ]) ++ [ final.python3.pkgs.ddt ];
  });
}
