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
  version = "1.3";
  pyproject = true;

  src = fetchFromGitLab {
    owner = "ldo";
    repo = "dbussy";
    rev = "v${version}";
    hash = "sha256-FSJpbsOGHfpafy9hfOENDyPDmolmjFDDpJEKnI4pkFc=";
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
