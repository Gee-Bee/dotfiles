{ config, pkgs, ... }:

let
  thumbnailScript = pkgs.writeScript "preemptive-thumbnails-fish" ''
    #!${pkgs.fish}/bin/fish

    # The freedesktop.org Thumbnail Managing Standard requires cache files to be
    # mode 0600 (thumbnails can leak the existence/content of private files to
    # other local users otherwise). Setting umask once here means every file we
    # create is correctly permissioned without an explicit chmod call.
    umask 077

    set DIRS "$HOME/Downloads" "$HOME/Pictures/Screenshots"
    # bucket:size pairs, per the freedesktop spec's "large"/"normal" sizes.
    # One list instead of two parallel ones (BUCKETS/SIZES) means bucket and
    # size can't drift out of sync if someone adds/reorders an entry later.
    set SPECS large:256 normal:128

    mkdir -p $DIRS
    for spec in $SPECS
      mkdir -p "$HOME/.cache/thumbnails/"(string split -m1 : -f1 $spec)
    end

    # Renders one bucket's thumbnail for a single source file.
    function make-thumbnail -a src uri mtime hash spec
      set -l parts (string split -m1 : $spec)
      set -l bucket $parts[1]
      set -l size $parts[2]
      set -l out "$HOME/.cache/thumbnails/$bucket/$hash.png"
      set -l tmp "$out.tmp.$fish_pid"

      # Metadata section: Thumb::URI and Thumb::MTime are mandatory per the
      # spec — file managers use Thumb::MTime to invalidate a cached
      # thumbnail if the source changed after it was generated. We don't
      # bother checking for an existing thumbnail before regenerating: the
      # hash alone doesn't tell us if the source changed since it was last
      # written, and re-reading the existing PNG's tEXt chunk to compare
      # mtimes would add real complexity for very little gain at this scale.
      ${pkgs.imagemagick}/bin/magick "$src" -auto-orient -thumbnail "$size"x"$size>" \
        -set "Thumb::URI" "$uri" \
        -set "Thumb::MTime" "$mtime" \
        "$tmp" >/dev/null
      # Write to a temp file first, then rename: `mv` within the same
      # directory is atomic, so Dolphin can never observe a half-written
      # PNG. Stderr is intentionally NOT suppressed — systemd captures it
      # in the journal, so a bad/corrupt source file shows up as a visible
      # failure instead of silently vanishing.
      and mv "$tmp" "$out"
    end

    # close_write catches files written directly (screenshots, most saves).
    # moved_to catches files that appear via rename-on-completion, which is how
    # browsers finish downloads (foo.jpg.crdownload -> foo.jpg) — without it,
    # completed downloads would never trigger a thumbnail.
    ${pkgs.inotify-tools}/bin/inotifywait -q -m -e close_write -e moved_to --format "%w%f" $DIRS | while read -l f
      string match -qr -i '\.(jpg|jpeg|png|webp|gif)$' "$f"; or continue

      # Guard against a race: the event can fire for a file that's already
      # been removed or renamed again by the time we get to process it
      # (e.g. editors that write-then-swap, or a download restarted).
      test -f "$f"; or continue

      # The spec's hash is over the *canonical* file:// URI. `path resolve`
      # gives us an absolute, symlink-free path so our hash matches what
      # Dolphin computes when it looks the thumbnail up — a mismatch here
      # (e.g. from a relative or symlinked path) means the thumbnail is
      # simply never found.
      set uri "file://"(path resolve "$f")
      set mtime (${pkgs.coreutils}/bin/date -r "$f" +%s)
      set hash (string sub -l 32 (echo -n $uri | ${pkgs.coreutils}/bin/md5sum))

      for spec in $SPECS
        make-thumbnail "$f" "$uri" "$mtime" "$hash" "$spec"
      end
    end
  '';
in
{
  systemd.user.services.preemptive-thumbnails = {
    description = "Pregenerate image thumbnails for Downloads and Screenshots";

    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];

    serviceConfig = {
      Type = "simple";
      ExecStart = "${thumbnailScript}";
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };
}
