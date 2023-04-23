This is a port of the compiler part of [vm2gol-v2 (Ruby version)](https://github.com/sonota88/vm2gol-v2).

```
  $ v version
V 0.3.3 88de0de
```

```sh
git clone --recursive https://github.com/sonota88/mini-ruccola-v.git
cd mini-ruccola-v

./docker.sh build
./test.sh all
```

```
  $ LANG=C wc -l mrcl_*.v lib/{types,utils}.v
  420 mrcl_codegen.v
  129 mrcl_lexer.v
  444 mrcl_parser.v
  173 lib/types.v
   50 lib/utils.v
 1216 total
```

---

```sh
  # format
./docker.sh run v fmt -w mrcl_*.v lib/*.v test/*.v
```
