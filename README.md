# AoikBackup
Backup scripts to archive files inside and outside repository directories separately.

Tested working with:
- Windows 10
- Cygwin 3.5.3-1.x86_64
- Cygwin find.exe (Package findutils 4.9.0-1)
- Cygwin test.exe (Package coreutils 9.0-1)
- Cygwin grep.exe (Package grep 3.11-1)
- Git for Windows 2.45.0
- 7-Zip for Windows 24.01

## Backup scenario
The directory to archive contains many repository directories (each of which containing a `.git` directory), as well as many other files outside these repository directories like documents and notes. To archive the whole directory is slow because these repository directories contain many small files, and may contain directories named `build`, `Build`, `dist`, `Dist`, `debug`, `Debug`, `release`, `Release`, `target`, `Target`, `node_modules`, `__pycache__` which are unwanted for a backup.

## Backup strategy
To archive the directory in the scenario stated above, we archive files inside and outside repository directories separately.

For files inside repository directories, archive only the `.git` directory. It contains blob files so is fast to archive.

This can be achieved by first using Cygwin `find.exe` to find out all the `.git` directories and then feed their paths to `7z.exe`, e.g.:
```
DEL /F /Q D:\Data.7z 2>NUL

SET PATH=D:\Software\7-Zip;D:\Software\Cygwin\bin;%PATH%

PUSHD D:\Data

find.exe "." -type "d" "(" -name "build" -o -name "Build" -o -name "dist" -o -name "Dist" -o -name "debug" -o -name "Debug" -o -name "release" -o -name "Release" -o -name "target" -o -name "Target" -o -name "node_modules" -o -name "__pycache__" ")" -prune -o -type "d" -name ".git" -exec "7z.exe" "-mx0" "-spf" "a" "D:\Data.7z" "{}" "+"

POPD
```
- `-prune` stops descending into unwanted directories.
- `-mx0` sets compression level to 0.
- `-spf` keeps the path prefix.

For files outside repository directories, archive all of them but exclude unwanted directories.

This can be achieved by using `7z.exe`'s exclude filters, e.g.:
```
SET PATH=D:\Software\7-Zip;%PATH%

PUSHD D:\Data

7z.exe -mx0 -spf -xr!"build" -xr!"Build" -xr!"dist" -xr!"Dist" -xr!"debug" -xr!"Debug" -xr!"release" -xr!"Release" -xr!"target" -xr!"Target" -xr!"node_modules" -xr!"__pycache__" -xr!"repo*" -xr!".git" a "D:\Data.7z" "."

POPD
```
- `DEL /F /Q D:\Data.7z 2>NUL` is not run because we want to add to the existing archive file.
- `-mx0` sets compression level to 0.
- `-spf` keeps the path prefix.

Notice the command above excludes repository directories the name of which matching wildcard `repo*`. This assumes the convention of naming all repository directories with a `repo` prefix. Without this convention, there is no way to exclude repository directories in `7z.exe`'s exclude filters. Although it is possible to use `find.exe` to filter and feed wanted paths to `7z.exe`, like the command below does, it is much slower due to the fact that, as limited by the command length, `7z.exe` will be run many times.
```
SET PATH=D:\Software\7-Zip;D:\Software\Cygwin\bin;%PATH%

PUSHD D:\Data

find.exe "." -type "d" "(" -name "build" -o -name "Build" -o -name "dist" -o -name "Dist" -o -name "debug" -o -name "Debug" -o -name "release" -o -name "Release" -o -name "target" -o -name "Target" -o -name "node_modules" -o -name "__pycache__" ")" -prune -o -type "d" -exec "test.exe" -d "{}/.git" ";" -prune -o -type "f" -exec "7z.exe" "-mx0" "-spf" "a" "D:\Data.7z" "{}" "+"

POPD
```
- This works but is much slower.
- `-prune` stops descending into unwanted directories.
- `-mx0` sets compression level to 0.
- `-spf` keeps the path prefix.

## Backup scripts
The backup scripts `aoik_backup_git.bat` and `aoik_backup_dir.bat` provided in this repository basically implement the backup strategy stated above.

Besides, they provide the following features to facilitate the backup process: 
1. Before archiving, run `git add -A` to add all unindexed files to git index, to avoid them being omitted.
2. Before archiving, run `git commit -m _MSG_` to commit all changes, to avoid them being omitted.
3. Before archiving, run `git fsck --full`,`git reflog expire --expire=now --all`, and `git gc --prune=now` to delete commits unreachable from all the branches or tags, and to compress files in the `.git` directory.
4. When an old archive file with the same name exists, rename it by adding a name postfix to it. After creating the new archive file finished with success, delete the renamed old archive file. If creating the new archive file finished with failure, the renamed old archive file is kept.
5. Abort immediately when any backup step fails, to avoid failure messages being overlooked.

## Backup script aoik_backup_git.bat help
Run:
```
CD AoikBackup\src

aoik_backup_git.bat --help 2>NUL
```

Result:
```
aoik_backup_git.bat _OPTIONS_

`_OPTIONS_`:
--src=_SRC_DIR_
  `_SRC_DIR_` is the path of the repository directory, which contains a `.git` directory, to archive.
  Required.

--dst=_ARCHIVE_FILE_
  `_ARCHIVE_FILE_` is the path of the archive file to be created.
  If `_ARCHIVE_FILE_` is empty, archiving is not performed but other tasks specified by options like `--git-add=1`, `--git-commit=1`, `--git-gc=1` may be performed.

--git-exe=_GIT_EXE_
  `_GIT_EXE_` is the path of the `git.exe` executable.
  The default is relative path `git.exe` thus requires `_GIT_ROOT_\bin` to be in environment variable `PATH`.

--git-add=0|1
  Whether to run `git add` before archiving.
  The default is 0.
  Effective only if `--git-commit=1`.

--git-commit=0|1
  Whether to run `git commit` before archiving.
  The default is 0.
  `git commit` requires `user.name` and `user.email` to be configured in `.gitconfig`.
  `git.exe` usually looks for `.gitconfig` in Windows' user home directory, but if `aoik_backup_git.bat` is run by a Cygwin program like `find.exe`, which is the case in `aoik_backup_dir.bat`, `git.exe` looks for `.gitconfig` in Cygwin's user home directory.

--git-commit-msg=_GIT_COMMIT_MSG_
  `_GIT_COMMIT_MSG_` is the git commit message.
  Effective only if `--git-commit=1`.

--git-gc=0|1
  Whether to run `git fsck --full`, `git reflog expire --expire=now --all` and `git gc --prune=now` before archiving.
  This deletes commits unreachable from all the branches or tags, and compresses files in the `.git` directory.
  The default is 0.

--7z-exe=_7Z_EXE_
  `_7Z_EXE_` is the path of the `7z.exe` executable.
  The default is relative path `7z.exe` thus requires `_7Z_ROOT_` to be in environment variable `PATH`.

--7z-opts=_7Z_OPTS_
  `_7Z_OPTS_` is the options passed to the `7z.exe` executable.
  The default is none.

--old-move=0|1
  Whether to move an existing archive file by adding a name postfix to it.
  The default is 0.

--old-move-del=0|1
  Whether to delete a moved existing archive file after the archiving finished with success.
  If the archiving finished with failure, the moved existing archive file is kept.
  The default is 0.
  Effective only if `--old-move=1`.

--old-move-postfix=_NAME_POSTFIX_
  The name postfix added to an existing archive file to be moved.
  The default is `.old`.
  Effective only if `--old-move=1`.

--dry-run
  Do a dry run to show parsed options and determined variables.

--help
  Show help.

--version
  Show version.
```

## Backup script aoik_backup_dir.bat help
Run:
```
CD AoikBackup\src

aoik_backup_dir.bat --help 2>NUL
```

Result:
```
aoik_backup_dir.bat _OPTIONS_

`_OPTIONS_`:
--src=_SRC_DIR_
  `_SRC_DIR_` is the path of the directory to archive.
  Required.

--dst=_ARCHIVE_FILE_
  `_ARCHIVE_FILE_` is the path of the archive file to be created.
  Required.

--mode=7Z|FIND_7Z|FIND_GIT_7Z
  The backup mode:
  `7Z`: run `7z.exe` directly.
  `FIND_7Z`: run `find.exe` and feed the paths found to `7z.exe`.
  `FIND_GIT_7Z`: run `find.exe` to search for `.git` directories and feed the paths found to `7z.exe`.
  The default is `7Z`.

--find-exe=_FIND_EXE_
  `_FIND_EXE_` is the path of the Cygwin `find.exe` executable.
  Not to be confused with `C:\Windows\System32\find.exe`.
  The default is relative path `find.exe` thus requires `_CYGWIN_ROOT_\bin` to be in environment variable `PATH`.
  Effective only if `--mode=FIND_7Z|FIND_GIT_7Z`.

--find-opts=_FIND_OPTS_
  `_FIND_OPTS_` is the options passed to the Cygwin `find.exe` executable.
  The default is none except for the hardcoded options.
  If `--mode=FIND_GIT_7Z`, `_FIND_OPTS_` is prepended to the first `find.exe` command's hardcoded options `-type "d" -exec "test.exe" "-d" "{}/.git"`, and to the second `find.exe` command's hardcoded options `-type "d" -name ".git"`.
  Effective only if `--mode=FIND_7Z|FIND_GIT_7Z`.

--test-exe=_TEST_EXE_
  `_TEST_EXE_` is the path of the Cygwin `test.exe` executable.
  The default is relative path `test.exe` thus requires `_CYGWIN_ROOT_\bin` to be in environment variable `PATH`.
  Effective only if `--mode=FIND_GIT_7Z`.

--grep-exe=_GREP_EXE_
  `_GREP_EXE_` is the path of the Cygwin `grep.exe` executable.
  The default is relative path `grep.exe` thus requires `_CYGWIN_ROOT_\bin` to be in environment variable `PATH`.
  Effective only if `--mode=FIND_GIT_7Z`.

--git-exe=_GIT_EXE_
  `_GIT_EXE_` is the path of the `git.exe` executable.
  The default is relative path `git.exe` thus requires `_GIT_ROOT_\bin` to be in environment variable `PATH`.
  Effective only if `--mode=FIND_GIT_7Z`.

--git-add=0|1
  Whether to run `git add` before archiving.
  The default is 0.
  Effective only if `--mode=FIND_GIT_7Z` and `--git-commit=1`.

--git-commit=0|1
  Whether to run `git commit` before archiving.
  The default is 0.
  Effective only if `--mode=FIND_GIT_7Z`.
  `git commit` requires `user.name` and `user.email` to be configured in `.gitconfig`.
  `aoik_backup_dir.bat` runs Cygwin's `find.exe`, which runs `aoik_backup_git.bat`, which runs `git.exe`.
  In this case, `git.exe` looks for `.gitconfig` in Cygwin's user home directory, not Windows' user home directory.

--git-commit-msg=_GIT_COMMIT_MSG_
  `_GIT_COMMIT_MSG_` is the git commit message.
  Effective only if `--mode=FIND_GIT_7Z` and `--git-commit=1`.

--git-gc=0|1
  Whether to run `git fsck --full`, `git reflog expire --expire=now --all` and `git gc --prune=now` before archiving.
  This deletes commits unreachable from all the branches or tags, and compresses files in the `.git` directory.
  The default is 0.
  Effective only if `--mode=FIND_GIT_7Z`.

--aoik-backup-git-bat=_AOIK_BACKUP_GIT_BAT_
  `_AOIK_BACKUP_GIT_BAT_` is the path of the `aoik_backup_git.bat` executable.
  The default is relative path `aoik_backup_git.bat`.
  Effective only if `--mode=FIND_GIT_7Z`.

--7z-exe=_7Z_EXE_
  `_7Z_EXE_` is the path of the `7z.exe` executable.
  The default is relative path `7z.exe` thus requires `_7Z_ROOT_` to be in environment variable `PATH`.

--7z-opts=_7Z_OPTS_
  `_7Z_OPTS_` is the options passed to the `7z.exe` executable.
  The default is none except for the hardcoded options.
  `_7Z_OPTS_` is prepended to the hardcoded options `-spf`.

--old-move=0|1
  Whether to move an existing archive file by adding a name postfix to it.
  The default is 0.

--old-move-del=0|1
  Whether to delete a moved existing archive file after the archiving finished with success.
  If the archiving finished with failure, the moved existing archive file is kept.
  The default is 0.
  Effective only if `--old-move=1`.

--old-move-postfix=_NAME_POSTFIX_
  The name postfix added to an existing archive file to be moved.
  The default is `.old`.
  Effective only if `--old-move=1`.

--dry-run
  Do a dry run to show parsed options and determined variables.

--help
  Show help.

--version
  Show version.
```

## Backup script aoik_backup_git.bat usage
Archive a repository directory which contains a `.git` directory:
```
SET PATH=D:\Software\Git\bin;D:\Software\7-Zip;%PATH%

CD AoikBackup\src

aoik_backup_git.bat --src="D:\Data\repo" --dst="D:\repo.7z" --git-add=1 --git-commit=1 --git-gc=1 --old-move=1 --old-move-del=1 --7z-opts="-mx0"
```
- `--git-gc=1` deletes commits unreachable from all the branches or tags, and compresses files in the `.git` directory. Use it only if the effect is well understood.
- `-mx0` sets compression level to 0.
- It runs faster without `--git-add=1 --git-commit=1 --git-gc=1`.

## Backup script aoik_backup_dir.bat usage
Archive `.git` directories under `D:\Data`.
```
SET PATH=D:\Software\Git\bin;D:\Software\7-Zip;D:\Software\Cygwin\bin;%PATH%

CD AoikBackup\src

aoik_backup_dir.bat --src="D:\Data" --dst="D:\Data.7z" --mode="FIND_GIT_7Z" --find-opts="-type d ( -name build -o -name Build -o -name dist -o -name Dist -o -name debug -o -name Debug -o -name release -o -name Release -o -name target -o -name Target -o -name node_modules -o -name __pycache__ ) -prune -o" --git-add=1 --git-commit=1 --git-gc=1 --old-move=1 --old-move-del=1 --7z-opts="-mx0"
```
- `-prune` stops descending into unwanted directories.
- `--git-gc=1` deletes commits unreachable from all the branches or tags, and compresses files in the `.git` directory. Use it only if the effect is well understood.
- `-mx0` sets compression level to 0.
- It runs faster without `--git-add=1 --git-commit=1 --git-gc=1`.

Archive files under `D:\Data` that are outside repository directories.
```
SET PATH=D:\Software\7-Zip;%PATH%

CD AoikBackup\src

aoik_backup_dir.bat --src="D:\Data" --dst="D:\Data.7z" --mode="7Z" --7Z-opts="-mx0 -xr!build -xr!Build -xr!dist -xr!Dist -xr!debug -xr!Debug -xr!release -xr!Release -xr!target -xr!Target -xr!node_modules -xr!__pycache__ -xr!repo* -xr!.git"
```
- `--old-move=1 --old-move-del=1` is not used because we want to add to the existing archive file.
- `-mx0` sets compression level to 0.
