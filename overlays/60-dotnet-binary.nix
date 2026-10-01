# Use Microsoft's prebuilt .NET tarballs instead of nixpkgs' source build.
#
# Since nixpkgs grew the VMR ("virtual mono repo") source build, the default
# dotnetCorePackages.sdk_* attributes compile the whole SDK from source. On
# aarch64-darwin that build fails in the runtime's native libs:
#
#   src/native/libs/build-native.proj(67,5): error MSB3073:
#     build-native.sh arm64 Release ... exited with code 2
#
# It is also a ~1h build nobody caches. Every dotnet consumer here is a
# prebuilt-friendly tool (csharpier, fantomas, fsautocomplete, netcoredbg,
# dotnet-sdk itself), so point them at the "-bin" variants, which are the
# official Microsoft tarballs that nixpkgs already ships alongside the VMR.
#
# Drop this overlay once the VMR builds on darwin upstream.

self: super: {
  dotnetCorePackages = super.dotnetCorePackages.overrideScope (
    _: prev:
    let
      channels = [ "8_0" "9_0" "10_0" "11_0" ];
      kinds = [ "sdk" "runtime" "aspnetcore" ];
      useBinary = kind: channel:
        let attr = "${kind}_${channel}"; in
        if prev ? "${attr}-bin"
        then { name = attr; value = prev."${attr}-bin"; }
        else null;
    in
    builtins.listToAttrs (
      builtins.filter (x: x != null) (
        super.lib.concatMap (kind: map (useBinary kind) channels) kinds
      )
    )
  );
}
