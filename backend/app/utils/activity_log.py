"""
Auto-commits activity log to GitHub whenever app data changes.
This makes app usage visible directly on the GitHub repository.
"""
import os
import subprocess
from datetime import datetime
import threading

LOG_FILE = os.path.join(
    os.path.dirname(__file__), '..', '..', '..', 'ACTIVITY_LOG.md'
)
REPO_DIR = os.path.join(
    os.path.dirname(__file__), '..', '..', '..'
)


def _commit_to_github(action: str, details: str = "") -> None:
    """Background thread — update ACTIVITY_LOG.md and push to GitHub."""
    try:
        log_path = os.path.abspath(LOG_FILE)
        repo_path = os.path.abspath(REPO_DIR)

        # Read existing log
        if os.path.exists(log_path):
            with open(log_path, 'r', encoding='utf-8') as f:
                content = f.read()
        else:
            content = "# Periodontal Recall AI — Live Activity Log\n\n"
            content += "> This file updates automatically when the app is used.\n\n"
            content += "| Timestamp (IST) | Action | Details |\n"
            content += "|-----------------|--------|---------|\n"

        # Add new entry
        ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        new_line = f"| {ts} | {action} | {details} |\n"

        # Insert after header
        lines = content.split('\n')
        for i, line in enumerate(lines):
            if line.startswith('|---'):
                lines.insert(i + 1, f"| {ts} | {action} | {details} |")
                break
        content = '\n'.join(lines)

        with open(log_path, 'w', encoding='utf-8') as f:
            f.write(content)

        # Git commit and push
        subprocess.run(['git', 'add', 'ACTIVITY_LOG.md'],
                       cwd=repo_path, capture_output=True)
        subprocess.run(['git', 'commit', '-m',
                        f'[live] {action} — {ts}'],
                       cwd=repo_path, capture_output=True)
        subprocess.run(['git', 'push'],
                       cwd=repo_path, capture_output=True)

    except Exception as e:
        pass  # Never block the API for git operations


def log_activity(action: str, details: str = "") -> None:
    """Non-blocking — runs git push in background thread."""
    t = threading.Thread(target=_commit_to_github,
                         args=(action, details), daemon=True)
    t.start()
