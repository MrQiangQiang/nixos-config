# Shared helper for Zig package builds using zig_0_16.fetchDeps.
# Copies fetched dependencies into the global cache directory expected by
# the Zig build system. This is needed because zig_0_16.hook does not
# automatically inject fetchDeps results into the cache.
zigDeps: ''
  export ZIG_GLOBAL_CACHE_DIR=$TMPDIR/zig-cache
  mkdir -p "$ZIG_GLOBAL_CACHE_DIR"

  if [ -d "${zigDeps}/p" ]; then
    cp -af "${zigDeps}/." "$ZIG_GLOBAL_CACHE_DIR/"
  else
    mkdir -p "$ZIG_GLOBAL_CACHE_DIR/p"
    cp -af "${zigDeps}/." "$ZIG_GLOBAL_CACHE_DIR/p/"
  fi

  chmod -R u+w "$ZIG_GLOBAL_CACHE_DIR"
''
