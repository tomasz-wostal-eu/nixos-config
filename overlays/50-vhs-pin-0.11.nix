# Pin vhs to 0.11.0.
#
# The 17.09.2026 nixpkgs bump moved vhs to 0.12.0, which is broken here: it
# parses the tape, prints "Creating <file>..." and exits 0 without writing
# anything. Verified 20.09 on darwin — .txt output works (written straight from
# the terminal buffer), while .gif and .mp4 produce no file and ffmpeg is never
# invoked at all, so it fails before encoding, in the go-rod frame capture.
# ffmpeg 9.0.1 is not at fault: it encodes synthetic clips fine, and an ffmpeg
# shim placed ahead of it in PATH is never called.
#
# 0.11.0 from the same store records both formats. Last known-good recordings
# in mistwolf-video-producer/assets/broll are from 19.08, before the bump.
#
# Drop this overlay once upstream vhs records again on darwin.

self: super: {
  vhs = super.vhs.overrideAttrs (old: rec {
    version = "0.11.0";

    src = super.fetchFromGitHub {
      owner = "charmbracelet";
      repo = "vhs";
      rev = "v${version}";
      hash = "sha256-VOiI+ddiax04QtCcDr6ze53kd/HHGbfQE3j/32iq4Ro=";
    };

    vendorHash = "sha256-cgKLYUATtn4hMdIOXZe9JWYNUOrX3S6BDfvS+rIWDfM=";
  });
}
