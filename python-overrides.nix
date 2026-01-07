{ pkgs }:
pyfinal: pyprev: {
  aiko-services = pyfinal.mkPythonEditablePackage {
    pname = "aiko-services";
    version = "1";
    root = "$REPO_ROOT/../aiko_services/src";
  };
  highlighter-sdk = pyfinal.buildPythonPackage rec {
    pname = "highlighter-sdk";
    version = "2.6.28";
    pyproject = true;

    src = pkgs.fetchPypi {
      pname = "highlighter_sdk";
      inherit version;
      hash = "sha256-AZ/kIhSI/O8NHlubG1vg3vKGJ0gZF8jXOTFRkOvYaYM=";
    };

    postPatch = ''
      substituteInPlace pyproject.toml \
        --replace-fail 'packages = ["src/highlighter", "src/aiko_services"]' \
                       'packages = ["highlighter", "aiko_services"]'

    '';

    buildInputs = with pyfinal; [ hatchling ];
    dependencies =
      with pyfinal;
      [
        alembic
        av
        boto3
        (pyfinal."cel-python")
        click
        colorama
        cookiecutter
        fastavro
        gql
        pandas
        pillow
        pooch
        pybreaker
        pydantic
        python-magic
        pyyaml
        requests
        scipy
        shapely
        sqlmodel
        tenacity
        tomli-w
        tqdm

        # aiko
        asciimatics
        avro
        avro-validator
        paho-mqtt
        psutil
        pyperclip
        pyzmq
        transitions
        wrapt
      ]
      ++ pyfinal.gql.optional-dependencies.aiohttp
      ++ pyfinal.gql.optional-dependencies.requests;

    optional-dependencies = with pyfinal; {
      cv2 = [ opencv4 ];
      predictors = [
        opencv4
        torch
        onnxruntime
      ];
      yolo = [
        opencv4
        torch
        onnx
        onnxruntime
        ultralytics
      ];
      tracker = [
        pykalman
        torch
      ];
      matplotlib = [ matplotlib ];
      rtspserver = [ pygobject3 ];
      hdf = [ tables ];
    };

    nativeBuildInputs = [ pyfinal.pythonRelaxDepsHook ];
    pythonRemoveDeps = [ "numpy" ];
    pythonRelaxDeps = [
      "alembic"
      "av"
      "avro"
      "boto3"
      "gql"
      "numpy"
      "paho-mqtt"
      "pillow"
      "psutil"
      "pydantic"
      "pyperclip"
      "pyzmq"
      "tomli-w"
      "websockets"
      "wrapt"
    ];
    # Disable the import check as `import aiko_services` uses the network
    pythonImportsCheck = [
      "aiko_services"
      "highlighter"
    ];
  };
  avro-validator = pyfinal.buildPythonPackage (rec {
    pname = "avro_validator";
    version = "1.2.1";
    format = "setuptools";
    src = pkgs.fetchFromGitHub {
      owner = "leocalm";
      repo = pname;
      rev = "refs/tags/${version}";
      hash = "sha256:17lxwy68r6wn3mpz3l7bi3ajg7xibp2sdz94hhjigfkxvz9jyi2f";
    };
    pythonImportsCheck = [ "avro_validator" ];
  });

  "cel-python" = pyfinal.buildPythonPackage ({
    pname = "cel-python";
    version = "0.4.0";
    format = "pyproject";

    src = pkgs.fetchFromGitHub {
      owner = "cloud-custodian";
      repo = "cel-python";
      rev = "bc7504741dbedf93f869f3024d9fbe431a37cf04";
      sha256 = "0wcsmwslfvkmi3agah8s5h1bh0m8irz54f60rvn7c39dbp9nqcll";
    };

    nativeBuildInputs = [ pyfinal.hatchling ];
    propagatedBuildInputs =
      with pyfinal;
      [
        google-re2
        jmespath
        lark
        pendulum
        pyyaml
      ]
      ++ pkgs.lib.optional (!pyfinal.pythonAtLeast "3.11") pyfinal.tomli;

    pythonImportsCheck = [ "celpy" ];
  });

  google-re2 = pyprev.google-re2.overridePythonAttrs (old: rec {
    version = "1.1.20250722";
    src = pyfinal.fetchPypi {
      pname = "google_re2";
      inherit version;
      sha256 = "sha256-XipGTfddvO+f4Nrxinj3PD8KUbgc24ZUYKBXmyJvLvM=";
    };
  });

  segmentation-models-pytorch = pyfinal.buildPythonPackage (rec {
    pname = "segmentation_models.pytorch";
    version = "0.5.0";
    pyproject = true;
    buildInputs = [ pyfinal.setuptools ];
    src = pkgs.fetchFromGitHub {
      owner = "qubvel-org";
      repo = pname;
      rev = "refs/tags/v${version}";
      hash = "sha256-QtrmMbVcFHftV69stJHk0+3n1o0inlO22xHs/smLlGg=";
    };
    dependencies = with pyfinal; [
      huggingface-hub
      numpy
      pillow
      safetensors
      timm
      torch
      torchvision
      tqdm
    ];
    optional-dependencies = {
      docs = with pyfinal; [
        autodocsumm
        huggingface-hub
        six
        sphinx
        sphinx-book-theme
      ];
      test = with pyfinal; [
        gitpython
        packaging
        pytest
        pytest-cov
        pytest-xdist
        ruff
        setuptools
      ];
    };
    pythonImportsCheck = [ "segmentation_models_pytorch" ];
  });

  pybreaker = pyfinal.buildPythonPackage (rec {
    pname = "pybreaker";
    version = "1.4.0";

    src = pyfinal.fetchPypi {
      inherit pname version;
      sha256 = "82910927d504aca596b5266964eaeabf41361aff30feb31d568d3e530fcc6f2b";
    };

    pyproject = true;
    nativeBuildInputs = [ pyfinal.flit-core ];
    propagatedBuildInputs = [ ];
    doCheck = true;

    checkInputs = [ pyfinal.pytest ];
  });

  # Override litellm to add cache extra support
  litellm = pyprev.litellm.overridePythonAttrs (old: {
    dependencies = old.dependencies or [ ] ++ [ pyfinal.diskcache ];
  });
}
