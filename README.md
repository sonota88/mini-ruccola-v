This is a port of the compiler part of [vm2gol-v2 (Ruby version)](https://github.com/sonota88/vm2gol-v2).

V言語でかんたんな自作言語のコンパイラを書いた  
https://memo88.hatenablog.com/entry/mini_ruccola_vlang

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
  417 mrcl_codegen.v
  129 mrcl_lexer.v
  444 mrcl_parser.v
  173 lib/types.v
   50 lib/utils.v
 1213 total

  $ wc -l lib/json.v
98 lib/json.v
```

---

```sh
  # format
./docker.sh run v fmt -w mrcl_*.v lib/*.v test/*.v
```
