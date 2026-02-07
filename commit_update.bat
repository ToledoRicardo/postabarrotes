@echo off
setlocal

set REPO_URL=https://github.com/HappyCarrot-php/postabarrotes.git
set BRANCH=main

if "%~1"=="" (
  set /p MSG=Commit message: 
) else (
  set MSG=%*
)

git rev-parse --is-inside-work-tree >nul 2>&1
if errorlevel 1 (
  echo Git repo not found. Initializing...
  git init
  if errorlevel 1 (
    echo Error: Git init failed.
    exit /b 1
  )
)

git remote get-url origin >nul 2>&1
if errorlevel 1 (
  git remote add origin %REPO_URL%
) else (
  git remote set-url origin %REPO_URL%
)

git add -A
git diff --cached --quiet
if errorlevel 1 (
  git commit -m "%MSG%"
  if errorlevel 1 (
    echo Error: Commit failed.
    exit /b 1
  ) else (
    echo Commit created successfully.
  )
) else (
  echo No changes to commit.
)

git branch -M %BRANCH%
git push -u origin %BRANCH%
if errorlevel 1 (
  echo Error: Push failed.
  exit /b 1
) else (
  echo Push succeeded.
)

endlocal
