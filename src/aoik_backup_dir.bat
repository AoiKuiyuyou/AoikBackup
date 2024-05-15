@ECHO OFF

REM # ++++++++++ AoikBatchCmdLineArgsParser [DisableDelayedExpansion] ++++++++++
REM # Version: 1.0.0
REM #
REM # Inspired by this post:
REM # https://stackoverflow.com/questions/3973824/windows-bat-file-optional-argument-parsing/8162578#8162578
REM #
REM # +++++ Features +++++
REM # - Supported to define a normal option or a flag option.
REM #
REM # - Supported to define an option key to contain `%`, `^`, `!` and ` `
REM #   space.
REM #
REM # - Supported to define an option default value to contain `%`, `^`, `!`
REM #   and ` ` space.
REM #
REM # - Supported to supply an option actual value to contain `%`, `^`, `!`
REM #   and ` ` space.
REM #
REM # - Supported to supply an option actual value that is empty.
REM #
REM # - Prevented `^` and `!` in an option definition from being treated
REM #   specially so no escaping or quoting is needed.
REM #
REM # - Prevented `-key` supplied from matching `--key` defined.
REM #
REM # - Provided both `DisableDelayedExpansion` and `EnableDelayedExpansion`
REM #   versions.
REM #
REM # - Added extensive comments to explain how the parsing works.
REM #
REM # +++++ Usage +++++
REM # - The `OPT_DEFS` variable contains a list of option definitions, delimited
REM #   by unquoted ` ` space.
REM #
REM # - An option definition is an `_OPT_KEY_:_OPT_DFT_` pair.
REM #   The option key and option default value are delimited by `:` colon.
REM #   E.g. `--title:test` defines a normal option taking a value.
REM #   E.g. `--version` defines a flag option taking no value.
REM #
REM # - `"` double quote should not be used either in an option definition, or
REM #   in the middle of a command line argument, because it would cause quote
REM #   mismatch which interferes with Batch's execution.
REM #
REM # - `'` single quote is used to quote option default values. It is not
REM #   allowed to be part of an option default value, but is ok to be part of
REM #   an option actual value.
REM #
REM # - Command line argument `--key=val` is automatically converted to two
REM #   arguments `--key` and `val` by CMD. The parser does not handle the
REM #   `--key=val` style directly. If the Batch script is not run by CMD, e.g.
REM #   by a Cygwin program instead, only the `--key val` style works, the
REM #  `--key=val` style not works.
REM #
REM # - If the execution failed with the error
REM #   `The syntax of the command is incorrect` or
REM #   `The system cannot find the batch label specified`,
REM #   it might be caused by a bug of Batch that has something to do with the
REM #   number of characters in the code. To let the error go away, try adding
REM #   some comment lines to the middle of the code.
REM #
REM # +++++ Examples +++++
REM # - To get result `--flag=1`, define option `--flag`, supply argument
REM #   `--flag`.
REM #
REM # - To get result `--key=val`, define option `--key:val`, supply argument
REM #   `--key val` or `--key=val`.
REM #
REM # - To get result `--key=`, define option `--key:''`, supply argument
REM #   `--key ""` or `--key=""`.
REM #
REM # - To get result `--%=%`, define option `--%%:%%`, supply argument `--% %`
REM #   or `--%=%`.
REM #
REM # - To get result `--^=^`, define option `--^:^`, supply argument
REM #   `"--^" "^"` or `"--^"="^"`.
REM #
REM # - To get result `--!=!`, define option `--!:!`, supply argument `--! !`
REM #   or `--!=!`.
REM #
REM # - To get result `--key with spaces=val with spaces`,
REM #   define option `'--key with spaces':'val with spaces'`,
REM #   supply argument `"--key with spaces" "val with spaces"`
REM #   or `"--key with spaces"="val with spaces"`.

REM # Create a local context. All variables set will not leak to outer context.
SETLOCAL DisableDelayedExpansion

REM # Set program name.
SET "PROG_NAME=aoik_backup_dir"

REM # Set log prefix.
SET "LOG_PREFIX=# +++++ [%PROG_NAME%] "

REM # Code below aims to define the command line options.
REM //ECHO 1>&2%LOG_PREFIX%INFO: 1D2T8: opts_define

REM # The command line option definitions.
SET "OPT_DEFS=--src:'' --dst:'' --mode:'7Z' --find-exe:'find.exe' --find-opts:'' --test-exe:'test.exe' --grep-exe:'grep.exe' --git-exe:'git.exe' --git-add:0 --git-commit:0 --git-commit-msg:'auto commit' --git-gc:0 --aoik-backup-git-bat:'aoik_backup_git.bat' --7z-exe:'7z.exe' --7z-opts:'' --old-move:0 --old-move-del:0 --old-move-postfix:'.old' --help --version --dry-run"

REM //ECHO 1>&2%LOG_PREFIX%DEBUG: 2L9V6: OPT_DEFS_INIT: "%OPT_DEFS%"

REM # Add a leading space and an ending space to the option definitions.
REM #
REM # This ensures each option key is preceded by a space, including the first
REM # one. This ensures each option default value is followed by a space,
REM # including the last one. The two facts ensured make some checks done below
REM # apply for the first and last option definitions too, besides option
REM # definitions in the middle.
REM #
SET "OPT_DEFS= %OPT_DEFS% "

REM //ECHO 1>&2%LOG_PREFIX%DEBUG: 4F9O1: OPT_DEFS_SP: "%OPT_DEFS%"

REM # ----- 3F1U5 -----
REM # Octuple `^` in `OPT_DEFS` to counteract the special treatment of
REM # unquoted `^` at 4C8I7, 2G4S9, 1X2D5, and 2Z9K3 below. The `^` octupling
REM # will be undone at 5Y1P6 and 6W9Q8.
SET "OPT_DEFS=%OPT_DEFS:^=^^^^^^^^%"

REM //ECHO 1>&2%LOG_PREFIX%DEBUG: 5C2U6: OPT_DEFS_OC: "%OPT_DEFS%"

REM # In `OPT_DEFS_SQ`, option keys and option default values are always quoted
REM # by `'`. They are appended at 3S5K4.
REM # Used to check the presence of an option key at 4X8U9.
REM #
REM # `SQ` means single quote.
REM #
SET "OPT_DEFS_SQ= "

REM # ----- 4C8I7 -----
REM # Convert `'` to `"` in `OPT_DEFS` so that when the `FOR` loop below does
REM # field splitting, quoted spaces in option default values are treated
REM # literally instead of as field delimiters.
REM #
REM # Enclosing `"` will cause quote mismatch for the variable expansion so is
REM # not used. As a result, unquoted `^` in `OPT_DEFS` will be treated
REM # specially during the expansion. The `^` octupling at 3F1U5 has prepared
REM # for this.
REM #
REM # `DQ` means double quote.
REM #
SET OPT_DEFS_DQ=%OPT_DEFS:'="%

REM //ECHO 1>&2%LOG_PREFIX%DEBUG: 6E9A8: OPT_DEFS_DQ: "%OPT_DEFS_DQ:"=~%" [`^"` shown as `~`]

REM # Code below aims to parse the option definitions.
REM //ECHO 1>&2%LOG_PREFIX%INFO: 7S5Q4: opt_defs_parse

REM # ----- 2G4S9 -----
REM # Parse the option definitions to set the default value for each option key.
REM #
REM # The `FOR` loop's field splitting by default uses unquoted spaces as
REM # delimiters. That is why `OPT_DEFS_DQ`, the double quote version of
REM # `OPT_DEFS` is used to preserve quoted spaces in default option values.
REM #
REM # Enclosing `"` will cause quote mismatch for the variable expansion so is
REM # not used. As a result, unquoted `^` in `OPT_DEFS_DQ` will be treated
REM # specially during the expansion. The `^` octupling at 3F1U5 has prepared
REM # for this.
REM #
REM # `%%O`: Each option definition.
REM # The `FOR` loop will not make a field empty so `%%O` must be nonempty.
REM #
FOR %%O IN (%OPT_DEFS_DQ%) DO (
  REM //ECHO 1>&2%LOG_PREFIX%DEBUG: 8P1N2: for_var: OPT_DEF: %%O

  REM # Code below aims to validate the option definition.
  REM //ECHO 1>&2%LOG_PREFIX%INFO: 9Y7K3: opt_def_validate

  REM # Store the option definition to variable `OPT_DEF`, to be accessed in the
  REM # subroutine below.
  SET OPT_DEF=%%O

  REM # Check if the option key in the option definition `OPT_DEF` is nonempty.
  REM #
  REM # This must be done in a subroutine because a subroutine can always access
  REM # the latest value of a variable set in a `FOR` loop, even if delayed
  REM # expansion is disabled.
  REM #
  CALL :opt_key_is_nonempty

  REM # If the option key in the option definition `OPT_DEF` is empty.
  IF ERRORLEVEL 1 (
    ECHO 1>&2%LOG_PREFIX%ERROR: 1T4Z2: option_key_empty: option_def=%%O
    GOTO :exit_code_1
  )

  REM # Code below aims to parse the option definition.
  REM //ECHO 1>&2%LOG_PREFIX%INFO: 2R7D3: opt_def_parse

  REM # Parse the option definition into option key and option default value.
  REM #
  REM # `delims=:`: Split the option definition pair `_OPT_KEY_:_OPT_DFT_` into
  REM # fields by delimiter `:`.
  REM #
  REM # `tokens=1,*`: Assign the first field `_OPT_KEY_` to `%%A`, assign the
  REM # rest `_OPT_DFT_` to `%%B`.
  REM #
  REM # `%%A`: option key `_OPT_KEY_`.
  REM #
  REM # `%%B`: option default value `_OPT_DFT_`.
  REM #
  REM # The enclosing `"` will not cause quote mismatch even if `%%O` contains
  REM # `"`.
  REM #
  FOR /f "delims=: eol= tokens=1,*" %%A IN ("%%O") DO (
    REM # `QC` means octuple caret.
    REM //ECHO 1>&2%LOG_PREFIX%DEBUG: 3F4X9: for_var: OPT_KEY_QC: %%A
    REM //ECHO 1>&2%LOG_PREFIX%DEBUG: 4L1W6: for_var: OPT_DFT_QC: %%B

    REM # Store the option key to variable `OPT_KEY_QC`, to be accessed in the
    REM # subroutine below.
    REM #
    REM # `QC` means octuple caret.
    REM #
    SET OPT_KEY_QC=%%A

    REM # ----- 5Y1P6 -----
    REM # Undo the `^` octupling in the option key `OPT_KEY_QC` done at 3F1U5.
    REM #
    REM # The subroutine sets variable `OPT_KEY_SQ`, to be used in the
    REM # subroutines `:opt_key_set_dft` and `:opt_defs_sq_append` below.
    REM #
    REM # This must be done in a subroutine because a subroutine can always
    REM # access the latest value of a variable set in a `FOR` loop, even if
    REM # delayed expansion is disabled.
    REM #
    CALL :opt_key_qc_undo

    REM # Store the option default value to variable `OPT_DFT_QC`, to be
    REM # accessed in the subroutine below.
    REM #
    REM # `QC` means octuple caret.
    REM #
    SET OPT_DFT_QC=%%B

    REM # ----- 6W9Q8 -----
    REM # Undo the `^` octupling in the option default value `OPT_DFT_QC` done
    REM # at 3F1U5.
    REM #
    REM # The subroutine sets variables `OPT_DFT_SQ` and `OPT_DFT_SQ_OR_EMPTY`,
    REM # to be used in the subroutines `:opt_key_set_dft` and
    REM # `:opt_defs_sq_append` below.
    REM #
    REM # This must be done in a subroutine because a subroutine can always
    REM # access the latest value of a variable set in a `FOR` loop, even if
    REM # delayed expansion is disabled.
    REM #
    CALL :opt_dft_qc_undo

    REM # Set the default value of the option key, using the variables
    REM # `OPT_KEY_SQ` and `OPT_DFT_SQ` set in the subroutines `opt_dft_qc_undo`
    REM # and `opt_key_qc_undo` above.
    REM #
    REM # This must be done in a subroutine because a subroutine can always
    REM # access the latest value of a variable set in a `FOR` loop, even if
    REM # delayed expansion is disabled.
    REM #
    CALL :opt_key_set_dft

    REM # If the `SET` command failed.
    REM #
    REM # This handles the case `SET "OPT_DEFS=' ':_OPT_DFT_"`.
    REM #
    IF ERRORLEVEL 1 (
      ECHO 1>&2%LOG_PREFIX%ERROR: 5J2E9: option_def_invalid: option_def=%%O
      GOTO :exit_code_1
    )

    REM # ----- 3S5K4 -----
    REM # Append the option key and option default value to `OPT_DEFS_SQ`, using
    REM # the variables `OPT_KEY_SQ` and `OPT_DFT_SQ_OR_EMPTY` set in the
    REM # subroutines `opt_dft_qc_undo` and `opt_key_qc_undo` above.
    REM #
    REM # In `OPT_DEFS_SQ`, option keys and option default values are always
    REM # quoted by `'`.
    REM #
    REM # This must be done in a subroutine because a subroutine can always
    REM # access the latest value of a variable set in a `FOR` loop, even if
    REM # delayed expansion is disabled.
    REM #
    CALL :opt_defs_sq_append
  )
)

REM //ECHO 1>&2%LOG_PREFIX%DEBUG: 6I3V1: OPT_DEFS_SQ: "%OPT_DEFS_SQ%"

REM # Double `^` in `OPT_DEFS_SQ`.
REM # Used to check the presence of an option key at 4X8U9.
REM #
REM # `SQ` means single quote.
REM # `DC` means double caret.
REM #
SET "OPT_DEFS_SQ_DC=%OPT_DEFS_SQ:^=^^%"

REM //ECHO 1>&2%LOG_PREFIX%DEBUG: 7A4O8: OPT_DEFS_SQ_DC: "%OPT_DEFS_SQ_DC%"

REM # Code below aims to parse the command line arguments into options.
REM //ECHO 1>&2%LOG_PREFIX%INFO: 8C6Q9: opts_parse

:opts_parse_loop
REM # If the option key in `%~1` is not empty.
REM #
REM # Code below assumes `%~1` and `%~2` contain no `"`.
REM # Otherwise it will cause quote mismatch.
REM #
IF NOT "%~1" == "" (
  REM //ECHO 1>&2%LOG_PREFIX%INFO: 9P5M1: opt_parse

  REM # ----- 4X8U9 -----
  REM # Remove the option key, the option definitions before it, and the colon
  REM # after it from `OPT_DEFS_SQ_DC`.
  REM #
  REM # E.g. `OPT_DEFS_SQ_DC` is ` '-a':'1' '-b':'2' '-c':'3' `, `%~1` is `-b`,
  REM # then `OPT_DEFS_REM` is `'2' '-c':'3' `.
  REM #
  REM # The meaning of `%%OPT_DEFS_SQ_DC:* '%~1':=%%`:
  REM # `%%` on both sides: Escape for `%`.
  REM # `:` before `* '%~1':`: Delimiter for variable content replacement.
  REM # `=` after `* '%~1':`: Delimiter for variable content replacement.
  REM # `*` of `* '%~1':`: Wildcard to match option definitions before the
  REM # option key.
  REM # ` ` of `* '%~1':`: The space before the option key in the option
  REM # definition. This aims to prevent e.g. the option key `-key` supplied
  REM # from matching `--key` defined.
  REM # `%~1` of `* '%~1':`: The option key in the option definition.
  REM # `:` of `* '%~1':`: The colon between the option key and the option
  REM # default value in the option definition.
  REM #
  REM # `CALL` will double `^` in `%~1`. That is why `OPT_DEFS_SQ_DC`,
  REM # the double caret version of `OPT_DEFS_SQ`, is used.
  REM # `CALL` will  not double `^` in `OPT_DEFS_SQ_DC` because `%%` escapes
  REM # thus `OPT_DEFS_SQ_DC` is not a variable as far as `CALL` concerns.
  REM #
  REM # The code run by `CALL` will do early expansion but not delayed
  REM # expansion even if the calling context has enabled delayed expansion.
  REM # The enclosing `"` keeps `^` from being treated specially by the early
  REM # expansion.
  REM #
  REM # Can not set `OPT_DEFS_REM` directly like
  REM # `SET "OPT_DEFS_REM=%OPT_DEFS_SQ:* '%~1':=%"`
  REM # because the syntax is invalid.
  REM.#
  REM # The enclosing `"` will not cause quote mismatch only if `%~1` contains
  REM # no `"`.
  REM.#
  CALL SET "OPT_DEFS_REM=%%OPT_DEFS_SQ_DC:* '%~1':=%%"

  REM # Check if the option key in `%~1` is defined.
  REM #
  REM # This must be done in a subroutine because a subroutine can always access
  REM # the latest value of a variable set in a `FOR` loop, even if delayed
  REM # expansion is disabled.
  REM #
  CALL :opt_key_is_defined

  REM # If the option key in `%~1` is not defined.
  IF ERRORLEVEL 1 (
    ECHO 1>&2%LOG_PREFIX%ERROR: 1G8K7: option_key_undefined: "%~1"
    GOTO :exit_code_1
  )

  REM # Check if the option key in `%~1` is a flag option.
  REM #
  REM # This must be done in a subroutine because a subroutine can always access
  REM # the latest value of a variable set in a `FOR` loop, even if delayed
  REM # expansion is disabled.
  REM #
  CALL :opt_key_is_flag

  IF NOT ERRORLEVEL 1 (
    REM # If the option key in `%~1` is a flag option.

    REM # Set the actual value of the option key.
    REM.#
    REM # The enclosing `"` will not cause quote mismatch only if `%~1` contains
    REM # no `"`.
    REM.#
    SET "%~1=1"

    REM # Shift off the option key.
    SHIFT /1
  ) ELSE (
    REM # If the option key in `%~1` is a normal option.

    REM # Set the actual value of the option key.
    REM.#
    REM # The enclosing `"` will not cause quote mismatch only if `%~1` and
    REM # `%~2` contain no `"`.
    REM.#
    SET "%~1=%~2"

    REM # Shift off the option key and option value.
    SHIFT /1
    SHIFT /1
  )

  GOTO :opts_parse_loop
) ELSE (
  REM # If the option key in `%~1` is empty.

  REM # If the next argument in `%~2` is not empty.
  IF NOT "%~2" == "" (
    ECHO 1>&2%LOG_PREFIX%ERROR: 2D3H9: option_key_empty
    GOTO :exit_code_1
  )
)
GOTO :opts_parse_end

:exit_code_0
REM # Exit with code 0.
REM #
REM # `EXIT /B 0` inside parentheses not sets the exit code properly.
REM # Use `GOTO :exit_code_0` instead.
REM #
EXIT /B 0

:exit_code_1
REM # Exit with code 1.
REM #
REM # `EXIT /B 1` inside parentheses not sets the exit code properly.
REM # Use `GOTO :exit_code_1` instead.
REM #
EXIT /B 1

:opt_key_is_nonempty
REM # Check if the option key in the option definition `OPT_DEF` is nonempty.

REM //ECHO 1>&2%LOG_PREFIX%DEBUG: 3B4X5: opt_key_is_nonempty: OPT_DEF: "%OPT_DEF:"=~%" [`^"` shown as `~`]

SET "OPT_DEF_SQ=%OPT_DEF:"='%"

REM //ECHO 1>&2%LOG_PREFIX%DEBUG: 4S8E2: opt_key_is_nonempty: OPT_DEF_SQ: "%OPT_DEF_SQ%"

REM # If the first character of the option definition is `:`.
REM #
REM # This handles the case `SET "OPT_DEFS=:_OPT_DFT_"`.
REM #
IF "%OPT_DEF_SQ:~0,1%" == ":" (
  EXIT /B 1
)

REM # If the first two characters of the option definition is `''`.
REM #
REM # This handles the case `SET "OPT_DEFS='':_OPT_DFT_"`.
REM #
IF "%OPT_DEF_SQ:~0,2%" == "''" (
  EXIT /B 1
)

EXIT /B 0

:opt_key_qc_undo
REM # Undo the `^` octupling in the option key `OPT_KEY_QC` done at 3F1U5.
REM #
REM # The subroutine sets variable `OPT_KEY_SQ`, to be used in the subroutines
REM # `:opt_key_set_dft` and `:opt_defs_sq_append` below.

REM # ----- 1X2D5 -----
REM # If the option key is empty.
REM #
REM # An empty variable can not do content replacement.
REM #
REM # Enclosing `"` will cause quote mismatch for the variable expansion so is
REM # not used. As a result, unquoted `^` in `OPT_KEY_QC` will be treated
REM # specially during the expansion. The `^` octupling  at 3F1U5 has prepared
REM # for this.
REM #
IF [%OPT_KEY_QC%] == [] (
  REM //ECHO 1>&2%LOG_PREFIX%DEBUG: 5I9W3: opt_key_qc_undo: OPT_KEY_QC: ""

  SET "OPT_KEY_SQ=''"

  EXIT /B 0
)

REM //ECHO 1>&2%LOG_PREFIX%DEBUG: 6F8Z1: opt_key_qc_undo: OPT_KEY_QC: "%OPT_KEY_QC:"=~%" [`^"` shown as `~`]

SET "OPT_KEY_QC_SQ=%OPT_KEY_QC:"='%"

REM //ECHO 1>&2%LOG_PREFIX%DEBUG: 7R4Q5: opt_key_qc_undo: OPT_KEY_QC_SQ: "%OPT_KEY_QC_SQ%"

IF "%OPT_KEY_QC_SQ:~0,1%" == "'" (
  REM # If the option key is quoted by `'`.

  REM # Undo the `^` octupling 3 times because not undone at 4C8I7 and 2G4S9.
  SET "OPT_KEY_SQ=%OPT_KEY_QC_SQ:^^^^^^^^=^%"
) ELSE (
  REM # If the option key is not quoted by `'`.

  REM # Undo the `^` octupling 1 time because already undone at 4C8I7 and 2G4S9.
  SET "OPT_KEY_SQ='%OPT_KEY_QC_SQ:^^=^%'"
)

REM //ECHO 1>&2%LOG_PREFIX%DEBUG: 8P9N1: opt_key_qc_undo: OPT_KEY_SQ: "%OPT_KEY_SQ%"

EXIT /B 0

:opt_dft_qc_undo
REM # Undo the `^` octupling in the option default value `OPT_DFT_QC` done at
REM # 3F1U5.
REM #
REM # The subroutine sets variables `OPT_DFT_SQ` and `OPT_DFT_SQ_OR_EMPTY`,
REM # to be used in the subroutines `:opt_key_set_dft` and `:opt_defs_sq_append`
REM # below.

REM # ----- 2Z9K3 -----
REM # If the option default value is empty.
REM #
REM # An empty variable can not do content replacement.
REM #
REM # Enclosing `"` will cause quote mismatch for the variable expansion so is
REM # not used. As a result, unquoted `^` in `OPT_DFT_QC` will be treated
REM # specially during the expansion. The `^` octupling at 3F1U5 has prepared
REM # for this.
REM #
IF [%OPT_DFT_QC%] == [] (
  REM //ECHO 1>&2%LOG_PREFIX%DEBUG: 9U2O4: opt_dft_qc_undo: OPT_DFT_QC: ""

  SET "OPT_DFT_SQ=''"
  SET "OPT_DFT_SQ_OR_EMPTY="

  EXIT /B 0
)

REM //ECHO 1>&2%LOG_PREFIX%DEBUG: 1L6J7: opt_dft_qc_undo: OPT_DFT_QC: "%OPT_DFT_QC:"=~%" [`^"` shown as `~`]

SET "OPT_DFT_QC_SQ=%OPT_DFT_QC:"='%"

IF "%OPT_DFT_QC_SQ:~0,1%" == "'" (
  REM # If the option default value is quoted by `'`.

  REM # Undo the `^` octupling 3 times because not undone at 4C8I7 and 2G4S9.
  SET "OPT_DFT_SQ=%OPT_DFT_QC_SQ:^^^^^^^^=^%"
) ELSE (
  REM # If the option key is not quoted by `'`.

  REM # Undo the `^` octupling 1 time because already undone at 4C8I7 and 2G4S9.
  SET "OPT_DFT_SQ='%OPT_DFT_QC_SQ:^^=^%'"
)

SET "OPT_DFT_SQ_OR_EMPTY=%OPT_DFT_SQ%"

EXIT /B 0

:opt_key_set_dft
REM # Set the default value of the option key, using the variables `OPT_KEY_SQ`
REM # and `OPT_DFT_SQ` set in the subroutines `opt_dft_qc_undo` and
REM # `opt_key_qc_undo` above.

REM //ECHO 1>&2%LOG_PREFIX%DEBUG: 2H8X9: opt_key_set_dft: OPT_KEY_SQ: "%OPT_KEY_SQ%"

REM //ECHO 1>&2%LOG_PREFIX%DEBUG: 3S4Y7: opt_key_set_dft: OPT_DFT_SQ: "%OPT_DFT_SQ%"

SET "%OPT_KEY_SQ:~1,-1%=%OPT_DFT_SQ:~1,-1%"

IF ERRORLEVEL 1 (
  EXIT /B 1
) ELSE (
  EXIT /B 0
)

:opt_defs_sq_append
REM # Append the option key and option default value to `OPT_DEFS_SQ`, using
REM # the variables `OPT_KEY_SQ` and `OPT_DFT_SQ_OR_EMPTY` set in the
REM # subroutines `opt_dft_qc_undo` and `opt_key_qc_undo` above.
REM #
REM # In `OPT_DEFS_SQ`, option keys and option default values are always quoted
REM # by `'`.

SET "OPT_DEFS_SQ=%OPT_DEFS_SQ%%OPT_KEY_SQ%:%OPT_DFT_SQ_OR_EMPTY% "

EXIT /B 0

:opt_key_is_defined
REM # Check if the option key in `%~1` is defined.

REM //ECHO 1>&2%LOG_PREFIX%DEBUG: 4E6T8: OPT_DEFS_REM: "%OPT_DEFS_REM%"

REM //ECHO 1>&2%LOG_PREFIX%DEBUG: 5C9B7: OPT_DEFS_SQ_DC: "%OPT_DEFS_SQ_DC%"

IF "%OPT_DEFS_REM%" == "%OPT_DEFS_SQ_DC%" (
  REM # If removed nothing from `OPT_DEFS_SQ_DC`, the option key is not defined.

  EXIT /B 1
) ELSE (
  REM # If removed something from `OPT_DEFS_SQ_DC`, the option key is defined.

  EXIT /B 0
)

:opt_key_is_flag
REM # Check if the option key in `%~1` is a flag option.

IF "%OPT_DEFS_REM:~0,1%" == " " (
  REM # If the first character of the option default value is a space, the
  REM # option key is a flag option.

  EXIT /B 0
) ELSE (
  REM # If the first character of the option default value is not a space, the
  REM # option key is a normal option.

  EXIT /B 1
)

:opts_parse_end

SET "OPT_DEFS="
SET "OPT_DEFS_SQ="
SET "OPT_DEFS_SQ_DC="
SET "OPT_DEFS_DQ="
SET "OPT_DEFS_REM="
SET "OPT_DEF="
SET "OPT_DEF_SQ="
SET "OPT_KEY_QC="
SET "OPT_KEY_QC_SQ="
SET "OPT_KEY_SQ="
SET "OPT_DFT_QC="
SET "OPT_DFT_QC_SQ="
SET "OPT_DFT_SQ="
SET "OPT_DFT_SQ_OR_EMPTY="
REM # ========== AoikBatchCmdLineArgsParser [DisableDelayedExpansion] ==========

REM # Enable delayed expansion so that variable expansion is as-is.
SETLOCAL EnableDelayedExpansion

SET SRC_DIR="!--src!"

SET ARCHIVE_PATH="!--dst!"

SET ARCHIVE_OLD_PATH="!--dst!!--old-move-postfix!"

SET MODE="!--mode!"

SET FIND_EXE_PATH="!--find-exe!"

REM # Unquoted to be expanded to multiple command options for `find.exe`.
SET FIND_OPTS=!--find-opts!

SET TEST_EXE_PATH="!--test-exe!"

SET GREP_EXE_PATH="!--grep-exe!"

SET GIT_EXE_PATH="!--git-exe!"

SET GIT_ADD_FLAG="!--git-add!"

SET GIT_COMMIT_FLAG="!--git-commit!"

SET GIT_COMMIT_MSG="!--git-commit-msg!"

SET GIT_GC_FLAG="!--git-gc!"

SET AOIK_BACKUP_GIT_BAT_PATH="!--aoik-backup-git-bat!"

SET ZIP_EXE_PATH="!--7z-exe!"

REM # Unquoted to be expanded to multiple command options for `7z.exe`.
SET ZIP_OPTS=!--7z-opts!

SET OLD_MOVE_FLAG="!--old-move!"

SET OLD_MOVE_DEL_FLAG="!--old-move-del!"

SET OLD_MOVE_POSTFIX="!--old-move-postfix!"

SET HELP_FLAG="!--help!"

SET VERSION_FLAG="!--version!"

SET DRY_RUN_FLAG="!--dry-run!"

ECHO 1>&2%LOG_PREFIX%STEP: 8B4U2: help_flag_check
IF [!HELP_FLAG!] == ["1"] (
  ECHO 1>&2%LOG_PREFIX%STEP: 6E3Z7: help_show
  ECHO aoik_backup_dir.bat _OPTIONS_
  ECHO.
  ECHO `_OPTIONS_`:
  ECHO --src=_SRC_DIR_
  ECHO.  `_SRC_DIR_` is the path of the directory to archive.
  ECHO.  Required.
  ECHO.
  ECHO --dst=_ARCHIVE_FILE_
  ECHO.  `_ARCHIVE_FILE_` is the path of the archive file to be created.
  ECHO.  Required.
  ECHO.
  ECHO --mode=7Z^|FIND_7Z^|FIND_GIT_7Z
  ECHO.  The backup mode:
  ECHO.  `7Z`: run `7z.exe` directly.
  ECHO.  `FIND_7Z`: run `find.exe` and feed the paths found to `7z.exe`.
  ECHO.  `FIND_GIT_7Z`: run `find.exe` to search for `.git` directories and feed the paths found to `7z.exe`.
  ECHO.  The default is `7Z`.
  ECHO.
  ECHO --find-exe=_FIND_EXE_
  ECHO.  `_FIND_EXE_` is the path of the Cygwin `find.exe` executable.
  ECHO.  Not to be confused with `C:\Windows\System32\find.exe`.
  ECHO.  The default is relative path `find.exe` thus requires `_CYGWIN_ROOT_\bin` to be in environment variable `PATH`.
  ECHO.  Effective only if `--mode=FIND_7Z^|FIND_GIT_7Z`.
  ECHO.
  ECHO --find-opts=_FIND_OPTS_
  ECHO.  `_FIND_OPTS_` is the options passed to the Cygwin `find.exe` executable.
  ECHO.  The default is none except for the hardcoded options.
  ECHO.  If `--mode=FIND_GIT_7Z`, `_FIND_OPTS_` is prepended to the first `find.exe` command's hardcoded options `-type "d" -exec "test.exe" "-d" "{}/.git"`, and to the second `find.exe` command's hardcoded options `-type "d" -name ".git"`.
  ECHO.  Effective only if `--mode=FIND_7Z^|FIND_GIT_7Z`.
  ECHO.
  ECHO --test-exe=_TEST_EXE_
  ECHO.  `_TEST_EXE_` is the path of the Cygwin `test.exe` executable.
  ECHO.  The default is relative path `test.exe` thus requires `_CYGWIN_ROOT_\bin` to be in environment variable `PATH`.
  ECHO.  Effective only if `--mode=FIND_GIT_7Z`.
  ECHO.
  ECHO --grep-exe=_GREP_EXE_
  ECHO.  `_GREP_EXE_` is the path of the Cygwin `grep.exe` executable.
  ECHO.  The default is relative path `grep.exe` thus requires `_CYGWIN_ROOT_\bin` to be in environment variable `PATH`.
  ECHO.  Effective only if `--mode=FIND_GIT_7Z`.
  ECHO.
  ECHO --git-exe=_GIT_EXE_
  ECHO.  `_GIT_EXE_` is the path of the `git.exe` executable.
  ECHO.  The default is relative path `git.exe` thus requires `_GIT_ROOT_\bin` to be in environment variable `PATH`.
  ECHO.  Effective only if `--mode=FIND_GIT_7Z`.
  ECHO.
  ECHO --git-add=0^|1
  ECHO.  Whether to run `git add` before archiving.
  ECHO.  The default is 0.
  ECHO.  Effective only if `--mode=FIND_GIT_7Z` and `--git-commit=1`.
  ECHO.
  ECHO --git-commit=0^|1
  ECHO.  Whether to run `git commit` before archiving.
  ECHO.  The default is 0.
  ECHO.  Effective only if `--mode=FIND_GIT_7Z`.
  ECHO.  `git commit` requires `user.name` and `user.email` to be configured in `.gitconfig`.
  ECHO.  `aoik_backup_dir.bat` runs Cygwin's `find.exe`, which runs `aoik_backup_git.bat`, which runs `git.exe`.
  ECHO.  In this case, `git.exe` looks for `.gitconfig` in Cygwin's user home directory, not Windows' user home directory.
  ECHO.
  ECHO --git-commit-msg=_GIT_COMMIT_MSG_
  ECHO.  `_GIT_COMMIT_MSG_` is the git commit message.
  ECHO.  Effective only if `--mode=FIND_GIT_7Z` and `--git-commit=1`.
  ECHO.
  ECHO --git-gc=0^|1
  ECHO.  Whether to run `git fsck --full`, `git reflog expire --expire=now --all` and `git gc --prune=now` before archiving.
  ECHO.  This deletes commits unreachable from all the branches or tags, and compresses files in the `.git` directory.
  ECHO.  The default is 0.
  ECHO.  Effective only if `--mode=FIND_GIT_7Z`.
  ECHO.
  ECHO --aoik-backup-git-bat=_AOIK_BACKUP_GIT_BAT_
  ECHO.  `_AOIK_BACKUP_GIT_BAT_` is the path of the `aoik_backup_git.bat` executable.
  ECHO.  The default is relative path `aoik_backup_git.bat`.
  ECHO.  Effective only if `--mode=FIND_GIT_7Z`.
  ECHO.
  ECHO --7z-exe=_7Z_EXE_
  ECHO.  `_7Z_EXE_` is the path of the `7z.exe` executable.
  ECHO.  The default is relative path `7z.exe` thus requires `_7Z_ROOT_` to be in environment variable `PATH`.
  ECHO.
  ECHO --7z-opts=_7Z_OPTS_
  ECHO.  `_7Z_OPTS_` is the options passed to the `7z.exe` executable.
  ECHO.  The default is none except for the hardcoded options.
  ECHO.  `_7Z_OPTS_` is prepended to the hardcoded options `-spf`.
  ECHO.
  ECHO --old-move=0^|1
  ECHO.  Whether to move an existing archive file by adding a name postfix to it.
  ECHO.  The default is 0.
  ECHO.
  ECHO --old-move-del=0^|1
  ECHO.  Whether to delete a moved existing archive file after the archiving finished with success.
  ECHO.  If the archiving finished with failure, the moved existing archive file is kept.
  ECHO.  The default is 0.
  ECHO.  Effective only if `--old-move=1`.
  ECHO.
  ECHO --old-move-postfix=_NAME_POSTFIX_
  ECHO.  The name postfix added to an existing archive file to be moved.
  ECHO.  The default is `.old`.
  ECHO.  Effective only if `--old-move=1`.
  ECHO.
  ECHO --dry-run
  ECHO.  Do a dry run to show parsed options and determined variables.
  ECHO.
  ECHO --help
  ECHO.  Show help.
  ECHO.
  ECHO --version
  ECHO.  Show version.

  GOTO :exit_code_0
)

ECHO 1>&2%LOG_PREFIX%STEP: 1Y4V8: version_flag_check
IF [!VERSION_FLAG!] == ["1"] (
  ECHO 1>&2%LOG_PREFIX%STEP: 2H9J3: version_show
  ECHO !VERSION!
  GOTO :exit_code_0
)

ECHO 1>&2%LOG_PREFIX%STEP: 9R6N2: opts_show
SET - >&2

ECHO 1>&2%LOG_PREFIX%STEP: 6S9T2: args_show
ECHO 1>&2SRC_DIR: !SRC_DIR!
ECHO 1>&2ARCHIVE_PATH: !ARCHIVE_PATH!
ECHO 1>&2ARCHIVE_OLD_PATH: !ARCHIVE_OLD_PATH!
ECHO 1>&2MODE: !MODE!
ECHO 1>&2FIND_EXE_PATH: !FIND_EXE_PATH!
ECHO 1>&2FIND_OPTS: "!FIND_OPTS!"
ECHO 1>&2TEST_EXE_PATH: !TEST_EXE_PATH!
ECHO 1>&2GREP_EXE_PATH: !GREP_EXE_PATH!
ECHO 1>&2GIT_EXE_PATH: !GIT_EXE_PATH!
ECHO 1>&2GIT_ADD_FLAG: !GIT_ADD_FLAG!
ECHO 1>&2GIT_COMMIT_FLAG: !GIT_COMMIT_FLAG!
ECHO 1>&2GIT_COMMIT_MSG: !GIT_COMMIT_MSG!
ECHO 1>&2GIT_GC_FLAG: !GIT_GC_FLAG!
ECHO 1>&2AOIK_BACKUP_GIT_BAT_PATH: !AOIK_BACKUP_GIT_BAT_PATH!
ECHO 1>&2ZIP_EXE_PATH: !ZIP_EXE_PATH!
ECHO 1>&2ZIP_OPTS: "!ZIP_OPTS!"
ECHO 1>&2OLD_MOVE_FLAG: !OLD_MOVE_FLAG!
ECHO 1>&2OLD_MOVE_DEL_FLAG: !OLD_MOVE_DEL_FLAG!
ECHO 1>&2OLD_MOVE_POSTFIX: !OLD_MOVE_POSTFIX!
ECHO 1>&2HELP_FLAG: !HELP_FLAG!
ECHO 1>&2VERSION_FLAG: !VERSION_FLAG!
ECHO 1>&2DRY_RUN_FLAG: !DRY_RUN_FLAG!

ECHO 1>&2%LOG_PREFIX%STEP: 2F3O6: dry_run_flag_check
IF [!DRY_RUN_FLAG!] == ["1"] (
  ECHO 1>&2%LOG_PREFIX%SUCCESS: 5C9E7: dry_run
  GOTO :exit_code_0
)

ECHO 1>&2%LOG_PREFIX%STEP: 1E9A6: src_dir_path_check
IF NOT EXIST !SRC_DIR!\ (
  ECHO 1>&2%LOG_PREFIX%FAILURE: 2R7M9: src_dir_not_exists: !SRC_DIR!
  GOTO :exit_code_1
)

ECHO 1>&2%LOG_PREFIX%STEP: 2X4Q3: archive_path_check
IF [!ARCHIVE_PATH!] == [""] (
  ECHO 1>&2%LOG_PREFIX%FAILURE: 3Q8G4: archive_path_empty
  GOTO :exit_code_1
)

ECHO 1>&2%LOG_PREFIX%STEP: 3W1M8: archive_old_path_check
IF [!ARCHIVE_OLD_PATH!] == [""] (
  ECHO 1>&2%LOG_PREFIX%FAILURE: 1T8V6: archive_old_path_empty
  GOTO :exit_code_1
)

ECHO 1>&2%LOG_PREFIX%STEP: 1Z6O8: mode_check
IF [!MODE!] == [""] (
  ECHO 1>&2%LOG_PREFIX%FAILURE: 2G9N4: mode_empty
  GOTO :exit_code_1
)

ECHO 1>&2%LOG_PREFIX%STEP: 1G4O3: old_move_postfix_check
IF [!OLD_MOVE_POSTFIX!] == [""] (
  ECHO 1>&2%LOG_PREFIX%FAILURE: 2U6E9: old_move_postfix_empty
  GOTO :exit_code_1
)

IF [!MODE!] == ["7Z"] (
  ECHO 1>&2%LOG_PREFIX%STEP: 6R2U9: 7z_exe_check
  CALL !ZIP_EXE_PATH! >NUL

  IF ERRORLEVEL 1 (
    ECHO 1>&2%LOG_PREFIX%FAILURE: 7C4P8: 7z_exe_path_invalid: !ZIP_EXE_PATH!
    GOTO :exit_code_1
  )
) ELSE IF [!MODE!] == ["FIND_7Z"] (
  ECHO 1>&2%LOG_PREFIX%STEP: 2D9Z3: find_exe_is_from_windows_check
  CALL !FIND_EXE_PATH! --version 2>&1 >NUL | findstr.exe /C:"FIND: Parameter format not correct"

  IF NOT ERRORLEVEL 1 (
    ECHO 1>&2%LOG_PREFIX%FAILURE: 3S1X7: find_exe_is_from_windows_not_cygwin: !FIND_EXE_PATH!
    GOTO :exit_code_1
  )

  ECHO 1>&2%LOG_PREFIX%STEP: 9I4W6: find_exe_check
  CALL !FIND_EXE_PATH! --version

  IF ERRORLEVEL 1 (
    ECHO 1>&2%LOG_PREFIX%FAILURE: 1O6D2: find_exe_path_invalid: !FIND_EXE_PATH!
    GOTO :exit_code_1
  )

  ECHO 1>&2%LOG_PREFIX%STEP: 4A5B2: 7z_exe_check
  CALL !ZIP_EXE_PATH! >NUL

  IF ERRORLEVEL 1 (
    ECHO 1>&2%LOG_PREFIX%FAILURE: 5R6J7: 7z_exe_path_invalid: !ZIP_EXE_PATH!
    GOTO :exit_code_1
  )
) ELSE IF [!MODE!] == ["FIND_GIT_7Z"] (
  ECHO 1>&2%LOG_PREFIX%STEP: 4W5Q1: find_exe_is_from_windows_check
  CALL !FIND_EXE_PATH! --version 2>&1 | findstr.exe /C:"FIND: Parameter format not correct" >NUL 2>NUL

  IF NOT ERRORLEVEL 1 (
    ECHO 1>&2%LOG_PREFIX%FAILURE: 1N2D3: find_exe_is_from_windows_not_cygwin: !FIND_EXE_PATH!
    GOTO :exit_code_1
  )

  ECHO 1>&2%LOG_PREFIX%STEP: 5J2U3: find_exe_check
  CALL !FIND_EXE_PATH! --version

  IF ERRORLEVEL 1 (
    ECHO 1>&2%LOG_PREFIX%FAILURE: 3Z4E5: find_exe_path_invalid: !FIND_EXE_PATH!
    GOTO :exit_code_1
  )

  ECHO 1>&2%LOG_PREFIX%STEP: 7M8X5: test_exe_check
  CALL !TEST_EXE_PATH! 1

  IF ERRORLEVEL 1 (
    ECHO 1>&2%LOG_PREFIX%FAILURE: 8N3T2: test_exe_path_invalid: !TEST_EXE_PATH!
    GOTO :exit_code_1
  )

  ECHO 1>&2%LOG_PREFIX%STEP: 9E6H2: grep_exe_check
  CALL !GREP_EXE_PATH! --version

  IF ERRORLEVEL 1 (
    ECHO 1>&2%LOG_PREFIX%FAILURE: 9I4R7: grep_exe_path_invalid: !GREP_EXE_PATH!
    GOTO :exit_code_1
  )

  ECHO 1>&2%LOG_PREFIX%STEP: 1A8Y7: aoik_backup_git_bat_check
  CALL !AOIK_BACKUP_GIT_BAT_PATH! --version

  IF ERRORLEVEL 1 (
    ECHO 1>&2%LOG_PREFIX%FAILURE: 1W5K2: aoik_backup_git_bat_path_invalid: !AOIK_BACKUP_GIT_BAT_PATH!
    GOTO :exit_code_1
  )

  ECHO 1>&2%LOG_PREFIX%STEP: 4S7O5: 7z_exe_check
  CALL !ZIP_EXE_PATH! >NUL

  IF ERRORLEVEL 1 (
    ECHO 1>&2%LOG_PREFIX%FAILURE: 5K8E3: 7z_exe_path_invalid: !ZIP_EXE_PATH!
    GOTO :exit_code_1
  )
) ELSE (
  ECHO 1>&2%LOG_PREFIX%FAILURE: 6E4U2: mode_invalid: !MODE!
  GOTO :exit_code_1
)

IF [!OLD_MOVE_FLAG!] == ["1"] (
  IF EXIST !ARCHIVE_PATH! (
    IF EXIST !ARCHIVE_OLD_PATH! (
      ECHO 1>&2%LOG_PREFIX%STEP: 3S5C4: archive_old_old_delete: !ARCHIVE_OLD_PATH!
      DEL /F /Q !ARCHIVE_OLD_PATH!

      IF ERRORLEVEL 1 (
        ECHO 1>&2%LOG_PREFIX%FAILURE: 4W2Y9: archive_old_old_delete: !ARCHIVE_OLD_PATH!
        GOTO :exit_code_1
      )
    )

    ECHO 1>&2%LOG_PREFIX%STEP: 6P2I4: archive_old_move
    MOVE !ARCHIVE_PATH! !ARCHIVE_OLD_PATH!

    IF ERRORLEVEL 1 (
      ECHO 1>&2%LOG_PREFIX%FAILURE: 7Y8X1: archive_old_move: !ARCHIVE_OLD_PATH!
      GOTO :exit_code_1
    )

    ECHO 1>&2%LOG_PREFIX%SUCCESS: 8U3L4: archive_old_move: !ARCHIVE_OLD_PATH!
  )
)

IF [!MODE!] == ["7Z"] (
  PUSHD !SRC_DIR!

  ECHO 1>&2%LOG_PREFIX%STEP: 8P6H3: archive_create
  REM # `-spf` keeps the path prefix.
  !ZIP_EXE_PATH! !ZIP_OPTS! -spf a !ARCHIVE_PATH! "."

  SET error_level=!ERRORLEVEL!

  POPD
) ELSE IF [!MODE!] == ["FIND_7Z"] (
  PUSHD !SRC_DIR!

  ECHO 1>&2%LOG_PREFIX%STEP: 6V2X9: archive_create
  REM # `-spf` keeps the path prefix.
  !FIND_EXE_PATH! "." !FIND_OPTS! -exec !ZIP_EXE_PATH! !ZIP_OPTS! -spf a !ARCHIVE_PATH! {} +

  SET error_level=!ERRORLEVEL!

  POPD
) ELSE IF [!MODE!] == ["FIND_GIT_7Z"] (
  PUSHD !SRC_DIR!

  SET GIT_RUN="0"
  IF [!GIT_COMMIT_FLAG!] == ["1"] (
    SET GIT_RUN="1"
  )
  IF [!GIT_GC_FLAG!] == ["1"] (
    SET GIT_RUN="1"
  )

  IF [!GIT_RUN!] == ["1"] (
    ECHO 1>&2%LOG_PREFIX%STEP: 3N8M9: aoik_backup_git_run
    !FIND_EXE_PATH! "." !FIND_OPTS! -type "d" -exec !TEST_EXE_PATH! -d "{}/.git" ";" -exec cmd.exe /C "1>&2" ECHO # +++++ [aoik_backup_dir] STEP: 9R4V3: aoik_backup_git_run_for_repo: "{}" ";" "(" -exec !AOIK_BACKUP_GIT_BAT_PATH! --src "{}" --git-add !GIT_ADD_FLAG! --git-commit !GIT_COMMIT_FLAG! --git-commit-msg !GIT_COMMIT_MSG! --git-gc !GIT_GC_FLAG! --git-exe !GIT_EXE_PATH! ";" -or -exec cmd.exe /C ECHO # +++++ [aoik_backup_dir] FAILURE: 2C9W3: aoik_backup_git_run_for_repo: "{}" ";" -quit ")" | !GREP_EXE_PATH! "\[aoik_backup_dir\] FAILURE: 2C9W3"

    IF NOT ERRORLEVEL 1 (
      ECHO 1>&2%LOG_PREFIX%FAILURE: 1B8W3: aoik_backup_git_run
      GOTO :exit_code_1
    )
  )

  ECHO 1>&2%LOG_PREFIX%STEP: 5E6X1: archive_create
  REM # `-spf` keeps the path prefix.
  !FIND_EXE_PATH! "." !FIND_OPTS! -type "d" -name ".git" -exec !ZIP_EXE_PATH! !ZIP_OPTS! -spf a !ARCHIVE_PATH! {} +

  SET error_level=!ERRORLEVEL!

  POPD
) ELSE (
  ECHO 1>&2%LOG_PREFIX%FAILURE: 9Q2R1: mode_invalid: !MODE!
  GOTO :exit_code_1
)

IF NOT [!error_level!] == [0] (
  ECHO 1>&2%LOG_PREFIX%FAILURE: 1E8P5: archive_create
  GOTO :exit_code_1
)

ECHO 1>&2%LOG_PREFIX%SUCCESS: 7Z5S9: archive_create: !ARCHIVE_PATH!

IF [!OLD_MOVE_FLAG!] == ["1"] (
  IF EXIST !ARCHIVE_OLD_PATH! (
    IF NOT [!OLD_MOVE_DEL_FLAG!] == ["1"] (
      ECHO 1>&2%LOG_PREFIX%SUCCESS: 3W1H7: archive_old_keep: !ARCHIVE_OLD_PATH!
    ) ELSE (
      ECHO 1>&2%LOG_PREFIX%STEP: 9K6T2: archive_old_delete: !ARCHIVE_OLD_PATH!
      DEL /F /Q !ARCHIVE_OLD_PATH!

      IF ERRORLEVEL 1 (
        ECHO 1>&2%LOG_PREFIX%FAILURE: 1S3A8: archive_old_delete: !ARCHIVE_OLD_PATH!
        GOTO :exit_code_1
      )

      ECHO 1>&2%LOG_PREFIX%SUCCESS: 2Z6Q9: archive_old_delete: !ARCHIVE_OLD_PATH!
    )
  )
)

ECHO 1>&2%LOG_PREFIX%SUCCESS: 7S9W5: all
EXIT /B 0
