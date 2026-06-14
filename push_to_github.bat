@echo off
cd /d "C:\Users\DELL\Documents\Project PDD"

echo === Initializing Git ===
git init

echo === Setting user config ===
git config user.name "ganeshreddy-178"
git config user.email "ganeshreddy@gmail.com"

echo === Adding all files ===
git add .

echo === Creating commit ===
git commit -m "Initial commit: Periodontal Recall AI - Complete B.Tech Project"

echo === Setting branch to main ===
git branch -M main

echo === Adding remote origin ===
git remote add origin https://github.com/ganeshreddy-178/periodontal-recall-ai.git

echo === Pushing to GitHub ===
git push -u origin main

echo.
echo === DONE! Check https://github.com/ganeshreddy-178/periodontal-recall-ai ===
pause
