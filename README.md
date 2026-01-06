**Example Usage**

```
  silverpondNix = builtins.fetchGit {
    url = "https://github.com/silverpond/silverpond-nix.git";
    rev = "3b2ba9d8e7726a169d2512c9a7219e44680abaf9";
  };
  bundlerEnvParams = {
    name = "highlighter";
    hash = "sha256-XXXXXXXXXXXXXXXXXXXXXXXXXXX";
    gemConfig = {
      appsignal = ''
        substituteInPlace ext/base.rb --replace-fail "[mirror, version, filename].join(\"/\")" "\"${import ./appsignal.nix pkgs}\""
        substituteInPlace ext/base.rb --replace-fail "return URI.open(*args)" "return URI.open(download_url)"
        cd ext
        ruby extconf.rb
        make
      '';
    };
    gemfile = ../Gemfile;
    gemfileLock = ../Gemfile.lock;
    inherit
      pkgs
      ruby
      bundler
      postgresql
      ;
  };
  wrappedRubyDev = import silverpondNix bundlerEnvParams;
  wrappedRubyProd = import silverpondNix (bundlerEnvParams // { prod = true; });
```

## Python Shell

Run the shell via HTTPS:
```bash
nix-shell https://github.com/silverpond/silverpond-nix/archive/master.tar.gz --arg cuda true
```
