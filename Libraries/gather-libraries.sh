#!/bin/bash
cp -L /usr/local/lib/libgmp.dylib .
cp -L /usr/local/lib/libmpfr.dylib .
cp -L /usr/local/lib/libmpfi.dylib .
cp -L /usr/local/lib/libflint.dylib .
cp -L /usr/local/lib/libarb.dylib .
install_name_tool -id '@loader_path/../Libraries/libgmp.dylib' libgmp.dylib
codesign --remove-signature libgmp.dylib

install_name_tool -id '@loader_path/../Libraries/libmpfr.dylib' libmpfr.dylib
install_name_tool -change '/usr/local/lib/libgmp.10.dylib' '@loader_path/../Libraries/libgmp.dylib' libmpfr.dylib
codesign --remove-signature libmpfr.dylib

install_name_tool -id '@loader_path/../Libraries/libmpfi.dylib' libmpfi.dylib
install_name_tool -change '/usr/local/lib/libgmp.10.dylib' '@loader_path/../Libraries/libgmp.dylib' libmpfi.dylib
install_name_tool -change '/usr/local/lib/libmpfr.6.dylib' '@loader_path/../Libraries/libmpfr.dylib' libmpfi.dylib
codesign --remove-signature libmpfi.dylib

install_name_tool -id '@loader_path/../Libraries/libflint.dylib' libflint.dylib
install_name_tool -change '/usr/local/lib/libgmp.10.dylib' '@loader_path/../Libraries/libgmp.dylib' libflint.dylib
install_name_tool -change '/usr/local/lib/libmpfr.6.dylib' '@loader_path/../Libraries/libmpfr.dylib' libflint.dylib
codesign --remove-signature libflint.dylib

install_name_tool -id '@loader_path/../Libraries/libarb.dylib' libarb.dylib
install_name_tool -change '/usr/local/lib/libgmp.10.dylib' '@loader_path/../Libraries/libgmp.dylib' libarb.dylib
install_name_tool -change '/usr/local/lib/libmpfr.6.dylib' '@loader_path/../Libraries/libmpfr.dylib' libarb.dylib
install_name_tool -change '@rpath/libflint.15.dylib' '@loader_path/../Libraries/libflint.dylib' libarb.dylib
codesign --remove-signature libarb.dylib
