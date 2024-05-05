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
SET "OPTS_SPEC=--src:'' --dst:'' --git-exe:'git.exe' --7z-exe:'7z.exe' --7z-opts:'' --git-add:0 --git-commit:0 --git-commit-msg:'auto commit' --git-gc:0 --old-move:0 --old-move-del:0 --old-move-postfix:'.old' --help: --version: --dry-run:"

REM # ++++++++++ Options parsing ++++++++++
REM # Options parsing code is modified from:
REM # https://stackoverflow.com/questions/3973824/windows-bat-file-optional-argument-parsing/8162578#8162578
REM # Unlike the original code, the modified version does not need delayed expansion.

ECHO 1>&2# +++++ [aoik_backup_git] STEP: 1Y7F4: opts_spec_parse
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
  REM // ECHO 1>&2# +++++ [aoik_backup_git] DEBUG: 2P6Q8: option_spec: %%O

  REM # Parse the option spec into option key and option default value.
  REM #
  REM # `delims=:`: split the option spec `_OPT_KEY_:_OPT_DFT_` into fields by delimiter `:`.
  REM # `tokens=1,*`: assign the first field (`_OPT_KEY_`) to `%%A`, assign the rest (`_OPT_DFT_`) to `%%B`.
  REM # `%%A`: option key, e.g. `--git-exe`.
  REM # `%%B`: option default value, e.g. `"git.exe"`.
  REM #
  FOR /f "delims=: tokens=1,*" %%A IN ("%%O") DO (
    REM // ECHO 1>&2# +++++ [aoik_backup_git] DEBUG: 3G9W1: option_key: %%A
    REM // ECHO 1>&2# +++++ [aoik_backup_git] DEBUG: 4H2O6: option_dft: %%B
    REM # Use the option key in `%%A` as variable name, set the variable to hold the option default value in `%%B`.
    SET "%%A=%%~B"
  )
)

ECHO 1>&2# +++++ [aoik_backup_git] STEP: 5P3I9: opts_parse
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

  REM // ECHO 1>&2# +++++ [aoik_backup_git] DEBUG: 6Q2W7: arg_1: %~1
  REM // ECHO 1>&2# +++++ [aoik_backup_git] DEBUG: 7X4F1: arg_2: %~2

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
    ECHO 1>&2# +++++ [aoik_backup_git] FAILURE: 8T5M9: option_invalid: %~1
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

SET GIT_DIR="!--src!\.git"

SET ARCHIVE_PATH="!--dst!"

IF [!ARCHIVE_PATH!] == [""] (
  SET ARCHIVE_OLD_PATH=""
) ELSE (
  SET ARCHIVE_OLD_PATH="!--dst!!--old-move-postfix!"
)

SET GIT_EXE_PATH="!--git-exe!"

SET GIT_ADD_FLAG="!--git-add!"

SET GIT_COMMIT_FLAG="!--git-commit!"

SET GIT_COMMIT_MSG="!--git-commit-msg!"

SET GIT_GC_FLAG="!--git-gc!"

SET ZIP_EXE_PATH="!--7z-exe!"

REM # Unquoted to be expanded to multiple command options for `7z.exe`.
SET ZIP_OPTS=!--7z-opts!

SET OLD_MOVE_FLAG="!--old-move!"

SET OLD_MOVE_DEL_FLAG="!--old-move-del!"

SET OLD_MOVE_POSTFIX="!--old-move-postfix!"

SET HELP_FLAG="!--help!"

SET VERSION_FLAG="!--version!"

SET DRY_RUN_FLAG="!--dry-run!"

ECHO 1>&2# +++++ [aoik_backup_git] STEP: 1K7G8: help_flag_check
IF [!HELP_FLAG!] == ["1"] (
  ECHO 1>&2# +++++ [aoik_backup_git] SUCCESS: 9C6A1: help_show
  ECHO aoik_backup_git.bat _OPTIONS_
  ECHO.
  ECHO `_OPTIONS_`:
  ECHO --src=_SRC_DIR_
  ECHO.  `_SRC_DIR_` is the path of the repository directory, which contains a `.git` directory, to archive.
  ECHO.  Required.
  ECHO.
  ECHO --dst=_ARCHIVE_FILE_
  ECHO.  `_ARCHIVE_FILE_` is the path of the archive file to be created.
  ECHO.  If `_ARCHIVE_FILE_` is empty, archiving is not performed but other tasks specified by options like `--git-add=1`, `--git-commit=1`, `--git-gc=1` may be performed.
  ECHO.
  ECHO --git-exe=_GIT_EXE_
  ECHO.  `_GIT_EXE_` is the path of the `git.exe` executable.
  ECHO.  The default is relative path `git.exe` thus requires `_GIT_ROOT_\bin` to be in environment variable `PATH`.
  ECHO.
  ECHO --git-add=0^|1
  ECHO.  Whether to run `git add` before archiving.
  ECHO.  The default is 0.
  ECHO.  Effective only if `--git-commit=1`.
  ECHO.
  ECHO --git-commit=0^|1
  ECHO.  Whether to run `git commit` before archiving.
  ECHO.  The default is 0.
  ECHO.  `git commit` requires `user.name` and `user.email` to be configured in `.gitconfig`.
  ECHO.  `git.exe` usually looks for `.gitconfig` in Windows' user home directory, but if `aoik_backup_git.bat` is run by a Cygwin program like `find.exe`, which is the case in `aoik_backup_dir.bat`, `git.exe` looks for `.gitconfig` in Cygwin's user home directory.
  ECHO.
  ECHO --git-commit-msg=_GIT_COMMIT_MSG_
  ECHO.  `_GIT_COMMIT_MSG_` is the git commit message.
  ECHO.  Effective only if `--git-commit=1`.
  ECHO.
  ECHO --git-gc=0^|1
  ECHO.  Whether to run `git fsck --full`, `git reflog expire --expire=now --all` and `git gc --prune=now` before archiving.
  ECHO.  This deletes commits unreachable from all the branches or tags, and compresses files in the `.git` directory.
  ECHO.  The default is 0.
  ECHO.
  ECHO --7z-exe=_7Z_EXE_
  ECHO.  `_7Z_EXE_` is the path of the `7z.exe` executable.
  ECHO.  The default is relative path `7z.exe` thus requires `_7Z_ROOT_` to be in environment variable `PATH`.
  ECHO.
  ECHO --7z-opts=_7Z_OPTS_
  ECHO.  `_7Z_OPTS_` is the options passed to the `7z.exe` executable.
  ECHO.  The default is none.
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

ECHO 1>&2# +++++ [aoik_backup_git] STEP: 2N3R4: version_flag_check
IF [!VERSION_FLAG!] == ["1"] (
  ECHO 1>&2# +++++ [aoik_backup_git] STEP: 5D1F2: version_show
  ECHO !VERSION!
  GOTO :exit_code_0
)

ECHO 1>&2# +++++ [aoik_backup_git] STEP: 9R6N2: opts_show
SET - >&2

ECHO 1>&2# +++++ [aoik_backup_git] STEP: 4U2O8: vars_show
ECHO 1>&2SRC_DIR: !SRC_DIR!
ECHO 1>&2GIT_DIR: !GIT_DIR!
ECHO 1>&2ARCHIVE_PATH: !ARCHIVE_PATH!
ECHO 1>&2ARCHIVE_OLD_PATH: !ARCHIVE_OLD_PATH!
ECHO 1>&2GIT_EXE_PATH: !GIT_EXE_PATH!
ECHO 1>&2GIT_ADD_FLAG: !GIT_ADD_FLAG!
ECHO 1>&2GIT_COMMIT_FLAG: !GIT_COMMIT_FLAG!
ECHO 1>&2GIT_COMMIT_MSG: !GIT_COMMIT_MSG!
ECHO 1>&2GIT_GC_FLAG: !GIT_GC_FLAG!
ECHO 1>&2ZIP_EXE_PATH: !ZIP_EXE_PATH!
ECHO 1>&2ZIP_OPTS: "!ZIP_OPTS!"
ECHO 1>&2OLD_MOVE_FLAG: !OLD_MOVE_FLAG!
ECHO 1>&2OLD_MOVE_DEL_FLAG: !OLD_MOVE_DEL_FLAG!
ECHO 1>&2OLD_MOVE_POSTFIX: !OLD_MOVE_POSTFIX!
ECHO 1>&2HELP_FLAG: !HELP_FLAG!
ECHO 1>&2VERSION_FLAG: !VERSION_FLAG!
ECHO 1>&2DRY_RUN_FLAG: !DRY_RUN_FLAG!

ECHO 1>&2# +++++ [aoik_backup_git] STEP: 3J9D1: dry_run_flag_check
IF [!DRY_RUN_FLAG!] == ["1"] (
  ECHO 1>&2# +++++ [aoik_backup_git] SUCCESS: 2X5M4: dry_run
  GOTO :exit_code_0
)

ECHO 1>&2# +++++ [aoik_backup_git] STEP: 1Z5V3: src_dir_check
IF NOT EXIST !SRC_DIR!\ (
  ECHO 1>&2# +++++ [aoik_backup_git] FAILURE: 2D9I7: src_dir_not_exists: !SRC_DIR!
  GOTO :exit_code_1
)

ECHO 1>&2# +++++ [aoik_backup_git] STEP: 4Z2E5: archive_old_path_check
IF NOT [!ARCHIVE_PATH!] == [""] IF [!ARCHIVE_OLD_PATH!] == [""] (
  ECHO 1>&2# +++++ [aoik_backup_git] FAILURE: 2G3A5: archive_old_path_empty
  GOTO :exit_code_1
)

ECHO 1>&2# +++++ [aoik_backup_git] STEP: 4T6P5: old_move_postfix_check
IF [!OLD_MOVE_POSTFIX!] == [""] (
  ECHO 1>&2# +++++ [aoik_backup_git] FAILURE: 5N8B7: old_move_postfix_empty
  GOTO :exit_code_1
)

ECHO 1>&2# +++++ [aoik_backup_git] STEP: 5U8B1: git_exe_check
!GIT_EXE_PATH! --version
IF ERRORLEVEL 1 (
  ECHO 1>&2# +++++ [aoik_backup_git] FAILURE: 6C9R2: git_exe_path_invalid: !GIT_EXE_PATH!
  GOTO :exit_code_1
)

IF [!GIT_COMMIT_FLAG!] == ["1"] (
  IF [!GIT_ADD_FLAG!] == ["1"] (
    ECHO 1>&2# +++++ [aoik_backup_git] STEP: 5S2K8: git_add
    !GIT_EXE_PATH! --git-dir !GIT_DIR! --work-tree !SRC_DIR! add -A
    IF ERRORLEVEL 1 (
      ECHO 1>&2# +++++ [aoik_backup_git] FAILURE: 7X2L8: git_add
      GOTO :exit_code_1
    )
  )

  ECHO 1>&2# +++++ [aoik_backup_git] STEP: 8I6Z5: git_diff_index
  !GIT_EXE_PATH! --git-dir !GIT_DIR! --work-tree !SRC_DIR! diff-index --quiet HEAD

  IF ERRORLEVEL 2 (
    ECHO 1>&2# +++++ [aoik_backup_git] FAILURE: 9U2E3: git_diff_index
    GOTO :exit_code_1
  )

  IF ERRORLEVEL 1 (
    ECHO 1>&2# +++++ [aoik_backup_git] STEP: 1W7J4: git_commit
    !GIT_EXE_PATH! --git-dir !GIT_DIR! --work-tree !SRC_DIR! commit -m !GIT_COMMIT_MSG!

    IF ERRORLEVEL 1 (
      ECHO 1>&2# +++++ [aoik_backup_git] FAILURE: 2D8H5: git_commit
      GOTO :exit_code_1
    )

    ECHO 1>&2# +++++ [aoik_backup_git] SUCCESS: 3N6G1: git_commit: msg=!GIT_COMMIT_MSG!
  ) ELSE (
    ECHO 1>&2# +++++ [aoik_backup_git] SUCCESS: 4A2Q8: git_commit: no_change
  )
)

IF [!GIT_GC_FLAG!] == ["1"] (
  ECHO 1>&2# +++++ [aoik_backup_git] STEP: 5C7P6: git_fsck
  !GIT_EXE_PATH! --git-dir !GIT_DIR! --work-tree !SRC_DIR! fsck --full

  IF ERRORLEVEL 3 (
    ECHO 1>&2# +++++ [aoik_backup_git] FAILURE: 6S1O2: git_fsck
    GOTO :exit_code_1
  )

  IF ERRORLEVEL 1 (
    ECHO 1>&2# +++++ [aoik_backup_git] SUCCESS: 7T8I4: git_fsck
  ) ELSE (
    ECHO 1>&2# +++++ [aoik_backup_git] SUCCESS: 8X1K3: git_fsck: no_change
  )

  ECHO 1>&2# +++++ [aoik_backup_git] STEP: 9E2L7: git_reflog_expire
  !GIT_EXE_PATH! --git-dir !GIT_DIR! --work-tree !SRC_DIR! reflog expire --expire=now --all

  IF ERRORLEVEL 2 (
    ECHO 1>&2# +++++ [aoik_backup_git] FAILURE: 1J8Z5: git_reflog_expire
    GOTO :exit_code_1
  )

  IF ERRORLEVEL 1 (
    ECHO 1>&2# +++++ [aoik_backup_git] SUCCESS: 2R3D7: git_reflog_expire
  ) ELSE (
    ECHO 1>&2# +++++ [aoik_backup_git] SUCCESS: 3H9Y4: git_reflog_expire: no_change
  )

  ECHO 1>&2# +++++ [aoik_backup_git] STEP: 4Q2P1: git_gc
  !GIT_EXE_PATH! --git-dir !GIT_DIR! --work-tree !SRC_DIR! gc --prune=now

  IF ERRORLEVEL 2 (
    ECHO 1>&2# +++++ [aoik_backup_git] FAILURE: 5U6B9: git_gc
    GOTO :exit_code_1
  )

  IF ERRORLEVEL 1 (
    ECHO 1>&2# +++++ [aoik_backup_git] SUCCESS: 6M7T8: git_gc
  ) ELSE (
    ECHO 1>&2# +++++ [aoik_backup_git] SUCCESS: 7F5O9: git_gc: no_change
  )
)

IF NOT [!ARCHIVE_PATH!] == [""] IF [!OLD_MOVE_FLAG!] == ["1"] (
  IF EXIST !ARCHIVE_PATH! (
    IF EXIST !ARCHIVE_OLD_PATH! (
      ECHO 1>&2# +++++ [aoik_backup_git] STEP: 8S4I6: archive_old_old_del: !ARCHIVE_OLD_PATH!
      DEL /F /Q !ARCHIVE_OLD_PATH!

      IF ERRORLEVEL 1 (
        ECHO 1>&2# +++++ [aoik_backup_git] FAILURE: 9W5X2: archive_old_old_del: !ARCHIVE_OLD_PATH!
        GOTO :exit_code_1
      )
    )

    ECHO 1>&2# +++++ [aoik_backup_git] STEP: 9B2Y5: archive_old_move

    MOVE !ARCHIVE_PATH! !ARCHIVE_OLD_PATH!

    IF ERRORLEVEL 1 (
      ECHO 1>&2# +++++ [aoik_backup_git] FAILURE: 6T9I3: archive_old_move: !ARCHIVE_OLD_PATH!
      GOTO :exit_code_1
    )

    ECHO 1>&2# +++++ [aoik_backup_git] SUCCESS: 5Z2V7: archive_old_move: !ARCHIVE_OLD_PATH!
  )
)

ECHO 1>&2# +++++ [aoik_backup_git] STEP: 8W4R6: archive_create
IF [!ARCHIVE_PATH!] == [""] (
  ECHO 1>&2# +++++ [aoik_backup_git] SUCCESS: 1K4C7: archive_create: empty_path_ignore
) ELSE (
  !ZIP_EXE_PATH! !ZIP_OPTS! a !ARCHIVE_PATH! !GIT_DIR!

  IF ERRORLEVEL 1 (
    ECHO 1>&2# +++++ [aoik_backup_git] FAILURE: 4P1Z2: archive_create
    GOTO :exit_code_1
  )

  ECHO 1>&2# +++++ [aoik_backup_git] SUCCESS: 9F3H1: archive_create: !ARCHIVE_PATH!
)

IF NOT [!ARCHIVE_PATH!] == [""] IF [!OLD_MOVE_FLAG!] == ["1"] (
  IF EXIST !ARCHIVE_OLD_PATH! (
    IF NOT [!OLD_MOVE_DEL_FLAG!] == ["1"] (
      ECHO 1>&2# +++++ [aoik_backup_git] SUCCESS: 3W9U4: archive_old_keep: !ARCHIVE_OLD_PATH!
    ) ELSE (
      ECHO 1>&2# +++++ [aoik_backup_git] STEP: 1K7D2: archive_old_delete: !ARCHIVE_OLD_PATH!
      DEL /F /Q !ARCHIVE_OLD_PATH!

      IF ERRORLEVEL 1 (
        ECHO 1>&2# +++++ [aoik_backup_git] FAILURE: 5Q3J6: archive_old_delete: !ARCHIVE_OLD_PATH!
        GOTO :exit_code_1
      )

      ECHO 1>&2# +++++ [aoik_backup_git] SUCCESS: 2Y4N3: archive_old_delete: !ARCHIVE_OLD_PATH!
    )
  )
)

ECHO 1>&2# +++++ [aoik_backup_git] SUCCESS: 8A1R3: all
EXIT /B 0
