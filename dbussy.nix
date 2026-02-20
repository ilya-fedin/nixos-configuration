{
  lib,
  buildPythonPackage,
  fetchFromGitLab,
  setuptools,
  wheel,
  dbus,
}:

buildPythonPackage rec {
  pname = "dbussy";
  version = "1.3-unstable-2024-08-31";
  pyproject = true;

  src = fetchFromGitLab {
    owner = "ldo";
    repo = "dbussy";
    rev = "35726d27fd0142ca13fb59e4e0a32e9d85b06659";
    hash = "sha256-aS8XvUirb50N8UHaedVP4It5SXhUq4m4Bo1fHTGWBgw=";
  };

  postPatch = ''
    substituteInPlace dbussy.py --replace-fail '"libdbus-1.so.3"' '"${lib.getLib dbus}/lib/libdbus-1.so.3"'
  '';

  build-system = [
    setuptools
    wheel
  ];

  pythonImportsCheck = [
    "dbussy"
  ];

  meta = {
    description = "Python-binding for D-Bus using asyncio";
    homepage = "https://gitlab.com/ldo/dbussy";
    license = lib.licenses.lgpl21Only;
    maintainers = with lib.maintainers; [ ];
  };
}
