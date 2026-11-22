# Real amd64 images: workloads and their instruction mix (E136)

- `run.sh MODE WORK K`: one workload (`sh`, `gzip`, `sha`, `py`, `node`, `gcc`, `redis`) at size K,
  timed. MODE `q` runs it under `qemu-x86_64 -L /r` (the image mounted at `/r` in the
  `g86m-qemu` container); MODE `n` runs it as the container's own code (Rosetta or QEMU,
  whichever OrbStack or Docker has). `bench.py` and `bench.js` are the Python and Node work;
  `gcc` compiles `tests/prim64/*.c` (copy them, with `prim.h`, next to `run.sh`).
- `chr.sh ROOT WORK K OUT` (on the oracle host): the workload in a chroot of an image's
  exported root, under `perf record -e instructions:u`, every child followed.
- `mix2.py OUT ROOT`: each sample's instruction read from its binary by objdump and put in a
  class (`cls.py`).
