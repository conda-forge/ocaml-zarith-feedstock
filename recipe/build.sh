#!/usr/bin/env bash
set -euxo pipefail

./configure -installdir "${PREFIX}/lib/ocaml"

# ocamlmklib records its -L options in zarith.cma/.cmxa, where prefix
# relocation NUL-pads them (cf. conda-forge/ocaml-feedstock#132). Link with
# -lgmp only and pass the search path through the environment; at use time
# conda-ocaml-mkexe adds -L${CONDA_PREFIX}/lib.
export LIBRARY_PATH="${PREFIX}/lib"

make -j1 LIBS=-lgmp LDFLAGS=
make install

# In-tree tests cannot find libgmp on macOS: test executables carry an
# @executable_path/../lib rpath ($SRC_DIR/lib from tests/), and the bytecode
# test loads dllzarith.so through the build env's ocamlrun. The installed
# dllzarith.so gets its rpath from rattler-build's relinking.
if [[ "${target_platform}" == osx-* ]]; then
  ln -s "${PREFIX}/lib" lib
  "${INSTALL_NAME_TOOL}" -add_rpath "${PREFIX}/lib" dllzarith.so
fi
make tests
