#!/bin/bash

set -o nounset

print_project_dir() {
  (
    cd "$(dirname "$0")"
    pwd
  )
}

readonly PROJECT_DIR="$(print_project_dir)"
readonly TEST_DIR="${PROJECT_DIR}/test"
readonly TEST_COMMON_DIR="${PROJECT_DIR}/test_common"
readonly TEMP_DIR="${PROJECT_DIR}/z_tmp"

MAX_ID_UTILS=5
MAX_ID_JSON=8 # of 8
MAX_ID_LEX=4
MAX_ID_PARSE=2
MAX_ID_COMPILE=27 # of 27

ERRS=""

# RUNNER_CMD=

run_test_utils() {
  $RUNNER_CMD test/test_utils.sh
}

run_test_json() {
  local infile="$1"; shift

  cat $infile | bin/test_json
}

run_lex() {
  local infile="$1"; shift

  cat $infile | bin/mrcl_lexer
}

run_parse() {
  local infile="$1"; shift

  cat $infile | bin/mrcl_parser
}

run_codegen() {
  local infile="$1"; shift

  cat $infile | bin/mrcl_codegen
}

# --------------------------------

setup() {
  mkdir -p ./z_tmp
}

build() {
  set -o errexit
  ./compile.sh test/test_json.v
  ./compile.sh mrcl_lexer.v
  ./compile.sh mrcl_parser.v
  ./compile.sh mrcl_codegen.v
  set +o errexit
}

postproc() {
  local stage="$1"; shift

  if [ "$ERRS" = "" ]; then
    echo "${stage}: ok"
  else
    echo "----"
    echo "FAILED: ${ERRS}" | sed -e 's/,/\n  /g'
    exit 1
  fi
}

get_ids() {
  local max_id="$1"; shift

  if [ $# -eq 1 ]; then
    echo "$1"
  else
    seq 1 $max_id
  fi
}

# --------------------------------

test_utils_nn() {
  local nn="$1"; shift

  echo "case ${nn}"

  # local temp_output_file="${TEMP_DIR}/test.txt"
  # local exp_file="${TEST_DIR}/utils/exp_${nn}.txt"

  # run_test_utils > $temp_output_file
  # if [ $? -ne 0 ]; then
  #   ERRS="${ERRS},${nn}_json"
  #   return
  # fi

  # ruby test/diff.rb text $exp_file $temp_output_file
  bash test/test_utils.sh "$nn"
  local status=$?
  if [ $status -ne 0 ]; then
    ERRS="${ERRS},utils_${nn}_diff"
    return
  fi
}

test_utils() {
  local ids="$(get_ids $MAX_ID_UTILS "$@")"

  for id in $ids; do
    test_utils_nn $(printf "%02d" $id)
  done
}

# --------------------------------

test_json_nn() {
  local nn="$1"; shift

  echo "case ${nn}"

  local input_file="${TEST_COMMON_DIR}/json/${nn}.json"
  local temp_json_file="${TEMP_DIR}/test.json"
  local exp_file="${TEST_COMMON_DIR}/json/${nn}.json"

  run_test_json $input_file > $temp_json_file
  if [ $? -ne 0 ]; then
    echo >&2
    echo "json >>$(cat -A $temp_json_file)<<" >&2
    ERRS="${ERRS},${nn}_json"
    return
  fi

  # ruby ${TEST_COMMON_DIR}/diff.rb json $exp_file $temp_json_file
  ruby ${TEST_COMMON_DIR}/diff.rb json-fmt $exp_file $temp_json_file
  if [ $? -ne 0 ]; then
    # meld $exp_file $temp_json_file &

    ERRS="${ERRS},json_${nn}_diff"
    return
  fi
}

test_json() {
  local ids="$(get_ids $MAX_ID_JSON "$@")"

  for id in $ids; do
    test_json_nn $(printf "%02d" $id)
  done
}

# --------------------------------

test_lex_nn() {
  local nn="$1"; shift

  echo "case ${nn}"

  local input_file="${TEST_COMMON_DIR}/lex/${nn}.mrcl"
  local temp_tokens_file="${TEMP_DIR}/test.tokens.txt"
  local exp_file="${TEST_COMMON_DIR}/lex/exp_${nn}.txt"

  run_lex $input_file > $temp_tokens_file
  if [ $? -ne 0 ]; then
    ERRS="${ERRS},${nn}_lex"
    return
  fi

  ruby test_common/diff.rb text $exp_file $temp_tokens_file
  if [ $? -ne 0 ]; then
    # meld $exp_file $temp_tokens_file &

    ERRS="${ERRS},lex_${nn}_diff"
    return
  fi
}

test_lex() {
  local ids="$(get_ids $MAX_ID_LEX "$@")"

  for id in $ids; do
    test_lex_nn $(printf "%02d" $id)
  done
}

# --------------------------------

test_parse_nn() {
  local nn="$1"; shift

  echo "case ${nn}"

  local input_file="${TEST_COMMON_DIR}/parse/${nn}.mrcl"
  local temp_tokens_file="${TEMP_DIR}/test.tokens.txt"
  local temp_vgt_file="${TEMP_DIR}/test.vgt.json"
  local exp_file="${TEST_COMMON_DIR}/parse/exp_${nn}.vgt.json"

  echo "  lex" >&2
  run_lex $input_file > $temp_tokens_file
  if [ $? -ne 0 ]; then
    ERRS="${ERRS},${nn}_lex"
    return
  fi

  echo "  parse" >&2
  run_parse $temp_tokens_file \
    > $temp_vgt_file
  if [ $? -ne 0 ]; then
    ERRS="${ERRS},${nn}_parse"
    return
  fi

  ruby test_common/diff.rb json-fmt $exp_file $temp_vgt_file
  if [ $? -ne 0 ]; then
    # meld $exp_file $temp_vga_file &

    ERRS="${ERRS},parse_${nn}_diff"
    return
  fi
}

# --------------------------------

test_parse() {
  local ids="$(get_ids $MAX_ID_PARSE "$@")"

  for id in $ids; do
    test_parse_nn $(printf "%02d" $id)
  done
}

# --------------------------------

test_compile_do_skip() {
  local nn="$1"; shift

  # for skip_nn in 26 27 28; do
  #   if [ "$nn" = "$skip_nn" ]; then
  #     return 0
  #   fi
  # done

  return 1
}

test_compile_nn() {
  local nn="$1"; shift

  echo "case ${nn}"

  if (test_compile_do_skip "$nn"); then
    echo "  ... skip" >&2
    return
  fi

  local temp_tokens_file="${TEMP_DIR}/test.tokens.txt"
  local temp_vgt_file="${TEMP_DIR}/test.vgt.json"
  local temp_vga_file="${TEMP_DIR}/test.vga.txt"
  local local_errs=""
  local exp_file="${TEST_COMMON_DIR}/compile/exp_${nn}.vga.txt"

  echo "  lex" >&2
  run_lex ${TEST_COMMON_DIR}/compile/${nn}.mrcl \
    > $temp_tokens_file
  if [ $? -ne 0 ]; then
    ERRS="${ERRS},${nn}_lex"
    local_errs="${local_errs},${nn}_lex"
    return
  fi

  echo "  parse" >&2
  run_parse $temp_tokens_file \
    > $temp_vgt_file
  if [ $? -ne 0 ]; then
    ERRS="${ERRS},${nn}_parse"
    local_errs="${local_errs},${nn}_parse"
    return
  fi

  echo "  codegen" >&2
  run_codegen $temp_vgt_file \
    > $temp_vga_file
  if [ $? -ne 0 ]; then
    ERRS="${ERRS},${nn}_codegen"
    local_errs="${local_errs},${nn}_codegen"
    return
  fi

  if [ "$local_errs" = "" ]; then
    ruby test_common/diff.rb asm $exp_file $temp_vga_file
    if [ $? -ne 0 ]; then
      # meld $exp_file $temp_vga_file &

      ERRS="${ERRS},compile_${nn}_diff"
      return
    fi
  fi
}

# --------------------------------

test_compile() {
  local ids="$(get_ids $MAX_ID_COMPILE "$@")"

  for id in $ids; do
    test_compile_nn $(printf "%02d" $id)
  done
}

# --------------------------------

test_all() {
  # echo "==== utils ===="
  # test_utils
  # if [ $? -ne 0 ]; then
  #   ERRS="${ERRS},${nn}_utils"
  #   return
  # fi

  echo "==== json ===="
  test_json
  if [ $? -ne 0 ]; then
    ERRS="${ERRS},${nn}_json"
    return
  fi

  echo "==== lex ===="
  test_lex
  if [ $? -ne 0 ]; then
    ERRS="${ERRS},${nn}_lex"
    return
  fi

  echo "==== parse ===="
  test_parse
  if [ $? -ne 0 ]; then
    ERRS="${ERRS},${nn}_parse"
    return
  fi

  echo "==== compile ===="
  test_compile
  if [ $? -ne 0 ]; then
    ERRS="${ERRS},${nn}_compile"
    return
  fi
}

# --------------------------------

container_main() {
  setup

  build

  cmd="$1"; shift
  case $cmd in
    utils | u*)    #task: Run utils tests
      test_utils "$@"
      postproc "utils"
      ;;

    json | j*)     #task: Run json tests
      test_json "$@"
      postproc "json"
      ;;

    lex | l*)      #task: Run lex tests
      test_lex "$@"
      postproc "lex"
      ;;

    parse | p*)    #task: Run parse tests
      test_parse "$@"
      postproc "parse"
      ;;

    compile | c*)  #task: Run compile tests
      test_compile "$@"
      postproc "compile"
      ;;

    all | a*)      #task: Run all tests
      test_all
      postproc "all"
      ;;

    *)
      echo "Tasks:"
      grep '#task: ' $0 | grep -v grep
      ;;
  esac
}

# --------------------------------

in_container() {
  env | grep --quiet IN_CONTAINER
}

if (in_container); then
  container_main "$@"
else
  # Run in container
  ./docker.sh run bash test.sh "$@"
fi
