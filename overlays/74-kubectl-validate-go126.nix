final: prev: {
  # kubectl-validate 0.0.4 vendors a kube-openapi whose SemanticError.Is
  # recurses forever under Go 1.27 (errors.Is), so its test suite hangs until
  # the 10m timeout and the binary would hang on the same error path. Build
  # with Go 1.26 until upstream bumps kube-openapi.
  kubectl-validate = prev.kubectl-validate.override {
    buildGoModule = final.buildGo126Module;
  };
}
