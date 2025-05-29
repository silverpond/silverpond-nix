{
  name,
  hash,
  pkgs,
  ruby,
  bundler,
  postgresql,
  gemfile,
  gemfileLock,
  gemConfig ? { },
  prod ? false,
}:
let
  lib = pkgs.lib;
  defaultGemConfig = {
    selenium-webdriver = ''
      substituteInPlace lib/selenium/webdriver/common/driver_finder.rb \
            --replace-fail "paths[:driver_path]" "'${pkgs.chromedriver}/bin/chromedriver'" \
            --replace-fail "paths[:browser_path]" "'${pkgs.chromium}/bin/chromium'"
    '';
    shrine = ''
      substituteInPlace lib/shrine/plugins/derivation_endpoint.rb --replace-fail "Content-Length" "content-length"
      substituteInPlace lib/shrine/plugins/derivation_endpoint.rb --replace-fail "Content-Type" "content-type"
      substituteInPlace lib/shrine/plugins/derivation_endpoint.rb --replace-fail "Content-Range" "content-range"
      substituteInPlace lib/shrine/plugins/derivation_endpoint.rb --replace-fail "Content-Disposition" "content-disposition"
    '';
  };
  vendoredGems = pkgs.stdenvNoCC.mkDerivation {
    name = "vendored-gems-${name}";
    dontUnpack = true;
    dontPatchShebangs = true;
    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    nativeBuildInputs = with pkgs; [
      git
      bundler
      ruby
    ];
    outputHash = hash;
    buildPhase = ''
      cp ${gemfile} Gemfile
      cp ${gemfileLock} Gemfile.lock
      mkdir $out
      HOME=$TMP
      export GIT_SSL_CAINFO="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
      bundle config cache_path $out
      bundle config set cache_all true
      bundle config set cache_all_platforms true
      BUNDLE_RETRY=10 BUNDLE_TIMEOUT=20 bundle cache --no-install
      cp Gemfile.lock $out/
      gem --version > $out/gem_version
    '';
  };

  mergedGemConfig = defaultGemConfig // gemConfig;
  gemNames = builtins.attrNames mergedGemConfig;
  gemFixes = map (gemName: ''
    set +e
    gemPath=$(${lib.getExe bundler} show ${gemName})
    failed=$?
    set -e
    if [[ $failed -eq "0" ]] ; then
    pushd $gemPath
    ${mergedGemConfig.${gemName}}
    popd 
    fi
      
  '') gemNames;

  gemPatchScript = pkgs.lib.strings.concatLines gemFixes;

in
pkgs.stdenv.mkDerivation {
  name = "ruby-env-${name}-${ruby.version}-${if prod then "prod" else "dev"}";
  dontUnpack = true;
  disallowedReferences = [ vendoredGems ];
  nativeBuildInputs =
    with pkgs;
    [
      ruby
      git
      bundler
      gnumake
      libyaml
      libexif
      postgresql
      geos
      makeBinaryWrapper
      libffi
      openssl
      removeReferencesTo
    ]
    ++ lib.optional stdenv.isLinux autoPatchelfHook;
  buildPhase = ''
    HOME=$TMP
    set -e
    gem --version > gem_version
    cmp ${gemfileLock} ${vendoredGems}/Gemfile.lock || (echo "Gemfile.lock content changed, update vendoredGems outputHash" && exit 1)
    cmp gem_version ${vendoredGems}/gem_version || (echo "vendoredGems were build using different version of gem, update vendoredGems outputHash" && exit 1 )
    cp ${gemfile} Gemfile
    cp ${gemfileLock} Gemfile.lock
    cp -a ${vendoredGems} bundler_wants_writable_cache_to_rewrite_gemspecs
    chmod -R +w bundler_wants_writable_cache_to_rewrite_gemspecs
    bundle config cache_path bundler_wants_writable_cache_to_rewrite_gemspecs
    bundle config path $out
    bundle config set frozen 'true'
    bundle config build.sassc --disable-lto
    bundle config set without '${pkgs.lib.optionalString (prod) "development test"}'
    bundle install --local

    ${gemPatchScript}

    pushd $(${bundler}/bin/bundle show tzinfo)
    substituteInPlace lib/tzinfo/data_sources/zoneinfo_data_source.rb --replace-fail "/etc/zoneinfo" "${pkgs.tzdata}/share/zoneinfo"
    popd

    mkdir $out/bin
    things="ruby gem"
    for i in $things; do
      makeWrapper ${ruby}/bin/$i $out/bin/$i \
            --set GEM_HOME $out/ruby/${ruby.version.libDir} \
            --set GEM_PATH $out/ruby/${ruby.version.libDir}
    done
    # this is so that patchShebangs picks up $out/bin/ruby
    export PATH=$out/bin:$PATH
    for i in $out/ruby/${ruby.version.libDir}/bin/*; do
      patchShebangs --build $i
      ln -s $i $out/bin/$(basename $i)
    done
    makeWrapper ${bundler}/bin/bundle $out/bin/bundle \
      --set BUNDLE_APP_CONFIG $out

    # removing reference to vendoredGems
    bundle config --delete cache_path
    cp -av $HOME/.bundle/config $out/config
    find "$out" -type f -exec remove-references-to -t ${vendoredGems} '{}' +
  '';
  passthru = {
    inherit vendoredGems;
  };
}
