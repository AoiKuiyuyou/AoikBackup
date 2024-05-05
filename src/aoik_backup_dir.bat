@ECHO OFF

REM # Create a local context. All variables set will not leak to outer context.
SETLOCAL DisableDelayedExpansion

SET VERSION=0.0.1

GOTO :opts_proc

:exit_code_0
REM # `EXIT /B 0` inside parentheses not sets the exit code properly.
REM # Use `GOTO :exit_code_0` instead.
EXIT /B 0

:exit_code_1
REM # `EXIT /B 1` inside parentheses not sets the exit code properly.
REM # Use `GOTO :exit_code_1` instead.
EXIT /B 1

:opts_proc
SET "OPTS_SPEC=--src:'' --dst:'' --mode:'7Z' --find-exe:'find.exe' --find-opts:'' --test-exe:'test.exe' --grep-exe:'grep.exe' --git-exe:'git.exe' --git-add:0 --git-commit:0 --git-commit-msg:'auto commit' --git-gc:0 --aoik-backup-git-bat:'aoik_backup_git.bat' --7z-exe:'7z.exe' --7z-opts:'' --old-move:0 --old-move-del:0 --old-move-postfix:'.old' --help: --version: --dry-run:"

REM # ++++++++++ Options parsing ++++++++++
REM # Options parsing code is modified from:
REM # https://stackoverflow.com/questions/3973824/windows-bat-file-optional-argument-parsing/8162578#8162578
REM # Unlike the original code, the modified version does not need delayed expansion.

ECHO 1>&2# +++++ [aoik_backup_dir] STEP: 1Y7F4: opts_spec_parse
REM # Add a leading space and an ending space.
REM # This ensures each option key is preceded by a space, including the first
REM # one. This ensures each option default value is followed by a space,
REM # including the last one. The two facts ensured make some checks done below
REM # apply for the first and last options too, besides options in the middle.
SET "OPTS_SPEC_EXT= %OPTS_SPEC% "

REM # Parse the option specs in `OPTS_SPEC_EXT` to set the default value for
REM # each option key.
REM #
REM # Option specs are separated by spaces.
REM # Each option spec is a `_OPT_KEY_:_OPT_DFT_` pair.
REM # E.g. `--git-exe:'git.exe'` (normal option taking a value).
REM # E.g. `--version:` (flag option taking no value).
REM #
REM # `:'="`: convert `'` to `"` in `OPTS_SPEC_EXT` so that spaces in option
REM # default values are treated as part of the string instead of delimiters.
REM #
REM # `%%O`: each option spec.
REM #
FOR %%O IN (%OPTS_SPEC_EXT:'="%) DO (
  REM // ECHO 1>&2# +++++ [aoik_backup_dir] DEBUG: 2P6Q8: option_spec: %%O

  REM # Parse the option spec into option key and option default value.
  REM #
  REM # `delims=:`: split the option spec `_OPT_KEY_:_OPT_DFT_` into fields by delimiter `:`.
  REM # `tokens=1,*`: assign the first field (`_OPT_KEY_`) to `%%A`, assign the rest (`_OPT_DFT_`) to `%%B`.
  REM # `%%A`: option key, e.g. `--git-exe`.
  REM # `%%B`: option default value, e.g. `"git.exe"`.
  REM #
  FOR /f "delims=: tokens=1,*" %%A IN ("%%O") DO (
    REM // ECHO 1>&2# +++++ [aoik_backup_dir] DEBUG: 3G9W1: option_key: %%A
    REM // ECHO 1>&2# +++++ [aoik_backup_dir] DEBUG: 4H2O6: option_dft: %%B
    REM # Use the option key in `%%A` as variable name, set the variable to hold the option default value in `%%B`.
    SET "%%A=%%~B"
  )
)

ECHO 1>&2# +++++ [aoik_backup_dir] STEP: 5P3I9: opts_parse
:opts_proc_loop
REM # If the option key candidate is not empty.
IF NOT "%~1" == "" (
  REM # Process the current option key candidate.
  REM #
  REM # Note `-a=1` is converted to `-a 1` in `CMD.exe` interactive mode so no
  REM # special handling is needed. In non-interactive mode, `-a=1` is passed
  REM # as one argument thus will not be recognized as an option key. Use `-a 1`
  REM # instead.
  REM #

  REM // ECHO 1>&2# +++++ [aoik_backup_dir] DEBUG: 6Q2W7: arg_1: %~1
  REM // ECHO 1>&2# +++++ [aoik_backup_dir] DEBUG: 7X4F1: arg_2: %~2

  REM # Set `OPTS_SPEC_REM_CUR` to hold the option default value and characters
  REM # following it for the option key candidate, by removing the option key
  REM # candidate.and characters preceding it and a colon after it from `OPTS_SPEC_EXT`.
  REM #
  REM # E.g. `%~1` is `-b`, `OPTS_SPEC_EXT` is ` -a:1 -b:2 -c:3 `, then
  REM # `OPTS_SPEC_REM_CUR` is `2 -c:3 `.
  REM #
  REM # The meaning of `%%OPTS_SPEC_EXT:* %~1:=%%`:
  REM # `%%` in both sides: escape for `%`.
  REM # `:` before `* %~1:`: syntax delimiter for variable content replacement.
  REM # `=` after `* %~1:`: syntax delimiter for variable content replacement.
  REM # `*` of `* %~1:`: wildcard to match characters preceding the option key candidate.
  REM # ` ` of `* %~1:`: the space before an option key.
  REM # `%~1` of `* %~1:`: command argument 1 unquoted, i.e. the option key candidate.
  REM # `:` of `* %~1:`: the colon between an option key and an option default value.
  REM #
  CALL SET "OPTS_SPEC_REM_CUR=%%OPTS_SPEC_EXT:* %~1:=%%"

  REM # Check if the option key candidate is defined in `OPTS_SPEC_EXT`, by
  REM # comparing `OPTS_SPEC_REM_CUR` with `OPTS_SPEC_EXT`.
  REM #
  REM # The check must be done in a subroutine because a subroutine can always
  REM # access the current value of `OPTS_SPEC_REM_CUR`, even if delayed
  REM # expansion is disabled.
  REM #
  CALL :opt_key_is_defined

  REM # If the option key candidate is not defined in `OPTS_SPEC_EXT`.
  IF ERRORLEVEL 1 (
    ECHO 1>&2# +++++ [aoik_backup_dir] FAILURE: 8T5M9: option_invalid: %~1
    GOTO :exit_code_1
  )

  REM # Check if the option key is a flag option, by checking if the first
  REM # character in `OPTS_SPEC_REM_CUR` is a space.
  REM #
  REM # The check must be done in a subroutine because a subroutine can always
  REM # access the current value of `OPTS_SPEC_REM_CUR`, even if delayed
  REM # expansion is disabled.
  REM #
  CALL :opt_key_is_flag

  IF ERRORLEVEL 1 (
    REM # If the option key is not a flag option.
    REM # Use the option key as variable name, set the variable to hold the
    REM # option value in `%~2`.
    SET "%~1=%~2"
    SHIFT /1
    SHIFT /1
  ) ELSE (
    REM # If the option key is a flag option.
    REM # Use the option key as variable name, set the variable to hold the
    REM # option value `1`.
    SET "%~1=1"
    SHIFT /1
  )

  GOTO :opts_proc_loop
)
GOTO :opts_proc_end

:opt_key_is_defined
IF "%OPTS_SPEC_REM_CUR%" == "%OPTS_SPEC_EXT%" (
  REM # If the option key candidate is not removed from `OPTS_SPEC_EXT`, it is
  REM # not defined in `OPTS_SPEC_EXT`.
  EXIT /B 1
) ELSE (
  REM # If the option key candidate is removed from `OPTS_SPEC_EXT`, it is
  REM # defined in `OPTS_SPEC_EXT`.
  EXIT /B
)

:opt_key_is_flag
REM # `:~0,1` gets the first character of the variable.
IF "%OPTS_SPEC_REM_CUR:~0,1%" == " " (
  REM # If the first character of the option default value is a space,
  REM # the option key is a flag option.
  EXIT /B
) ELSE (
  REM # If the first character of the option default value is not a space,
  REM # the option key is not a flag option.
  EXIT /B 1
)

:opts_proc_end
REM # ========== Options parsing ==========

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

ECHO 1>&2# +++++ [aoik_backup_dir] STEP: 8B4U2: help_flag_check
IF [!HELP_FLAG!] == ["1"] (
  ECHO 1>&2# +++++ [aoik_backup_dir] STEP: 6E3Z7: help_show
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

ECHO 1>&2# +++++ [aoik_backup_dir] STEP: 1Y4V8: version_flag_check
IF [!VERSION_FLAG!] == ["1"] (
  ECHO 1>&2# +++++ [aoik_backup_dir] STEP: 2H9J3: version_show
  ECHO !VERSION!
  GOTO :exit_code_0
)

ECHO 1>&2# +++++ [aoik_backup_dir] STEP: 9R6N2: opts_show
SET - >&2

ECHO 1>&2# +++++ [aoik_backup_dir] STEP: 6S9T2: args_show
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

ECHO 1>&2# +++++ [aoik_backup_dir] STEP: 2F3O6: dry_run_flag_check
IF [!DRY_RUN_FLAG!] == ["1"] (
  ECHO 1>&2# +++++ [aoik_backup_dir] SUCCESS: 5C9E7: dry_run
  GOTO :exit_code_0
)

ECHO 1>&2# +++++ [aoik_backup_dir] STEP: 1E9A6: src_dir_path_check
IF NOT EXIST !SRC_DIR!\ (
  ECHO 1>&2# +++++ [aoik_backup_dir] FAILURE: 2R7M9: src_dir_not_exists: !SRC_DIR!
  GOTO :exit_code_1
)

ECHO 1>&2# +++++ [aoik_backup_dir] STEP: 2X4Q3: archive_path_check
IF [!ARCHIVE_PATH!] == [""] (
  ECHO 1>&2# +++++ [aoik_backup_dir] FAILURE: 3Q8G4: archive_path_empty
  GOTO :exit_code_1
)

ECHO 1>&2# +++++ [aoik_backup_dir] STEP: 3W1M8: archive_old_path_check
IF [!ARCHIVE_OLD_PATH!] == [""] (
  ECHO 1>&2# +++++ [aoik_backup_dir] FAILURE: 1T8V6: archive_old_path_empty
  GOTO :exit_code_1
)

ECHO 1>&2# +++++ [aoik_backup_dir] STEP: 1Z6O8: mode_check
IF [!MODE!] == [""] (
  ECHO 1>&2# +++++ [aoik_backup_dir] FAILURE: 2G9N4: mode_empty
  GOTO :exit_code_1
)

ECHO 1>&2# +++++ [aoik_backup_dir] STEP: 1G4O3: old_move_postfix_check
IF [!OLD_MOVE_POSTFIX!] == [""] (
  ECHO 1>&2# +++++ [aoik_backup_dir] FAILURE: 2U6E9: old_move_postfix_empty
  GOTO :exit_code_1
)

IF [!MODE!] == ["7Z"] (
  ECHO 1>&2# +++++ [aoik_backup_dir] STEP: 6R2U9: 7z_exe_check
  CALL !ZIP_EXE_PATH! >NUL

  IF ERRORLEVEL 1 (
    ECHO 1>&2# +++++ [aoik_backup_dir] FAILURE: 7C4P8: 7z_exe_path_invalid: !ZIP_EXE_PATH!
    GOTO :exit_code_1
  )
) ELSE IF [!MODE!] == ["FIND_7Z"] (
  ECHO 1>&2# +++++ [aoik_backup_dir] STEP: 2D9Z3: find_exe_is_from_windows_check
  CALL !FIND_EXE_PATH! --version 2>&1 >NUL | findstr.exe /C:"FIND: Parameter format not correct"

  IF NOT ERRORLEVEL 1 (
    ECHO 1>&2# +++++ [aoik_backup_dir] FAILURE: 3S1X7: find_exe_is_from_windows_not_cygwin: !FIND_EXE_PATH!
    GOTO :exit_code_1
  )

  ECHO 1>&2# +++++ [aoik_backup_dir] STEP: 9I4W6: find_exe_check
  CALL !FIND_EXE_PATH! --version

  IF ERRORLEVEL 1 (
    ECHO 1>&2# +++++ [aoik_backup_dir] FAILURE: 1O6D2: find_exe_path_invalid: !FIND_EXE_PATH!
    GOTO :exit_code_1
  )

  ECHO 1>&2# +++++ [aoik_backup_dir] STEP: 4A5B2: 7z_exe_check
  CALL !ZIP_EXE_PATH! >NUL

  IF ERRORLEVEL 1 (
    ECHO 1>&2# +++++ [aoik_backup_dir] FAILURE: 5R6J7: 7z_exe_path_invalid: !ZIP_EXE_PATH!
    GOTO :exit_code_1
  )
) ELSE IF [!MODE!] == ["FIND_GIT_7Z"] (
  ECHO 1>&2# +++++ [aoik_backup_dir] STEP: 4W5Q1: find_exe_is_from_windows_check
  CALL !FIND_EXE_PATH! --version 2>&1 | findstr.exe /C:"FIND: Parameter format not correct" >NUL 2>NUL

  IF NOT ERRORLEVEL 1 (
    ECHO 1>&2# +++++ [aoik_backup_dir] FAILURE: 1N2D3: find_exe_is_from_windows_not_cygwin: !FIND_EXE_PATH!
    GOTO :exit_code_1
  )

  ECHO 1>&2# +++++ [aoik_backup_dir] STEP: 5J2U3: find_exe_check
  CALL !FIND_EXE_PATH! --version

  IF ERRORLEVEL 1 (
    ECHO 1>&2# +++++ [aoik_backup_dir] FAILURE: 3Z4E5: find_exe_path_invalid: !FIND_EXE_PATH!
    GOTO :exit_code_1
  )

  ECHO 1>&2# +++++ [aoik_backup_dir] STEP: 7M8X5: test_exe_check
  CALL !TEST_EXE_PATH! 1

  IF ERRORLEVEL 1 (
    ECHO 1>&2# +++++ [aoik_backup_dir] FAILURE: 8N3T2: test_exe_path_invalid: !TEST_EXE_PATH!
    GOTO :exit_code_1
  )

  ECHO 1>&2# +++++ [aoik_backup_dir] STEP: 9E6H2: grep_exe_check
  CALL !GREP_EXE_PATH! --version

  IF ERRORLEVEL 1 (
    ECHO 1>&2# +++++ [aoik_backup_dir] FAILURE: 9I4R7: grep_exe_path_invalid: !GREP_EXE_PATH!
    GOTO :exit_code_1
  )

  ECHO 1>&2# +++++ [aoik_backup_dir] STEP: 1A8Y7: aoik_backup_git_bat_check
  CALL !AOIK_BACKUP_GIT_BAT_PATH! --version

  IF ERRORLEVEL 1 (
    ECHO 1>&2# +++++ [aoik_backup_dir] FAILURE: 1W5K2: aoik_backup_git_bat_path_invalid: !AOIK_BACKUP_GIT_BAT_PATH!
    GOTO :exit_code_1
  )

  ECHO 1>&2# +++++ [aoik_backup_dir] STEP: 4S7O5: 7z_exe_check
  CALL !ZIP_EXE_PATH! >NUL

  IF ERRORLEVEL 1 (
    ECHO 1>&2# +++++ [aoik_backup_dir] FAILURE: 5K8E3: 7z_exe_path_invalid: !ZIP_EXE_PATH!
    GOTO :exit_code_1
  )
) ELSE (
  ECHO 1>&2# +++++ [aoik_backup_dir] FAILURE: 6E4U2: mode_invalid: !MODE!
  GOTO :exit_code_1
)

IF [!OLD_MOVE_FLAG!] == ["1"] (
  IF EXIST !ARCHIVE_PATH! (
    IF EXIST !ARCHIVE_OLD_PATH! (
      ECHO 1>&2# +++++ [aoik_backup_dir] STEP: 3S5C4: archive_old_old_delete: !ARCHIVE_OLD_PATH!
      DEL /F /Q !ARCHIVE_OLD_PATH!

      IF ERRORLEVEL 1 (
        ECHO 1>&2# +++++ [aoik_backup_dir] FAILURE: 4W2Y9: archive_old_old_delete: !ARCHIVE_OLD_PATH!
        GOTO :exit_code_1
      )
    )

    ECHO 1>&2# +++++ [aoik_backup_dir] STEP: 6P2I4: archive_old_move
    MOVE !ARCHIVE_PATH! !ARCHIVE_OLD_PATH!

    IF ERRORLEVEL 1 (
      ECHO 1>&2# +++++ [aoik_backup_dir] FAILURE: 7Y8X1: archive_old_move: !ARCHIVE_OLD_PATH!
      GOTO :exit_code_1
    )

    ECHO 1>&2# +++++ [aoik_backup_dir] SUCCESS: 8U3L4: archive_old_move: !ARCHIVE_OLD_PATH!
  )
)

IF [!MODE!] == ["7Z"] (
  PUSHD !SRC_DIR!

  ECHO 1>&2# +++++ [aoik_backup_dir] STEP: 8P6H3: archive_create
  REM # `-spf` keeps the path prefix.
  !ZIP_EXE_PATH! !ZIP_OPTS! -spf a !ARCHIVE_PATH! "."

  SET error_level=!ERRORLEVEL!

  POPD
) ELSE IF [!MODE!] == ["FIND_7Z"] (
  PUSHD !SRC_DIR!

  ECHO 1>&2# +++++ [aoik_backup_dir] STEP: 6V2X9: archive_create
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
    ECHO 1>&2# +++++ [aoik_backup_dir] STEP: 3N8M9: aoik_backup_git_run
    !FIND_EXE_PATH! "." !FIND_OPTS! -type "d" -exec !TEST_EXE_PATH! -d "{}/.git" ";" -exec cmd.exe /C "1>&2" ECHO # +++++ [aoik_backup_dir] STEP: 9R4V3: aoik_backup_git_run_for_repo: "{}" ";" "(" -exec !AOIK_BACKUP_GIT_BAT_PATH! --src "{}" --git-add !GIT_ADD_FLAG! --git-commit !GIT_COMMIT_FLAG! --git-commit-msg !GIT_COMMIT_MSG! --git-gc !GIT_GC_FLAG! --git-exe !GIT_EXE_PATH! ";" -or -exec cmd.exe /C ECHO # +++++ [aoik_backup_dir] FAILURE: 2C9W3: aoik_backup_git_run_for_repo: "{}" ";" -quit ")" | !GREP_EXE_PATH! "\[aoik_backup_dir\] FAILURE: 2C9W3"

    IF NOT ERRORLEVEL 1 (
      ECHO 1>&2# +++++ [aoik_backup_dir] FAILURE: 1B8W3: aoik_backup_git_run
      GOTO :exit_code_1
    )
  )

  ECHO 1>&2# +++++ [aoik_backup_dir] STEP: 5E6X1: archive_create
  REM # `-spf` keeps the path prefix.
  !FIND_EXE_PATH! "." !FIND_OPTS! -type "d" -name ".git" -exec !ZIP_EXE_PATH! !ZIP_OPTS! -spf a !ARCHIVE_PATH! {} +

  SET error_level=!ERRORLEVEL!

  POPD
) ELSE (
  ECHO 1>&2# +++++ [aoik_backup_dir] FAILURE: 9Q2R1: mode_invalid: !MODE!
  GOTO :exit_code_1
)

IF NOT [!error_level!] == [0] (
  ECHO 1>&2# +++++ [aoik_backup_dir] FAILURE: 1E8P5: archive_create
  GOTO :exit_code_1
)

ECHO 1>&2# +++++ [aoik_backup_dir] SUCCESS: 7Z5S9: archive_create: !ARCHIVE_PATH!

IF [!OLD_MOVE_FLAG!] == ["1"] (
  IF EXIST !ARCHIVE_OLD_PATH! (
    IF NOT [!OLD_MOVE_DEL_FLAG!] == ["1"] (
      ECHO 1>&2# +++++ [aoik_backup_dir] SUCCESS: 3W1H7: archive_old_keep: !ARCHIVE_OLD_PATH!
    ) ELSE (
      ECHO 1>&2# +++++ [aoik_backup_dir] STEP: 9K6T2: archive_old_delete: !ARCHIVE_OLD_PATH!
      DEL /F /Q !ARCHIVE_OLD_PATH!

      IF ERRORLEVEL 1 (
        ECHO 1>&2# +++++ [aoik_backup_dir] FAILURE: 1S3A8: archive_old_delete: !ARCHIVE_OLD_PATH!
        GOTO :exit_code_1
      )

      ECHO 1>&2# +++++ [aoik_backup_dir] SUCCESS: 2Z6Q9: archive_old_delete: !ARCHIVE_OLD_PATH!
    )
  )
)

ECHO 1>&2# +++++ [aoik_backup_dir] SUCCESS: 7S9W5: all
EXIT /B 0
