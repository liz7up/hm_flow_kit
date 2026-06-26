#!/usr/bin/env python3
"""Statusline for Claude Code."""

import json, os, subprocess, sys

def get_branch():
    try:
        r = subprocess.run(['git', 'branch', '--show-current'],
                          capture_output=True, text=True, timeout=3,
                          cwd='/storage/Users/currentUser/Documents/repo/hm_flow_kit')
        b = r.stdout.strip()
        if not b:
            return '?'
        cwd = os.getcwd()
        if '/.claude/worktrees/' in cwd:
            wt = cwd.split('/.claude/worktrees/')[1].split('/')[0]
            return '{} [WT:{}]'.format(b, wt)
        return b
    except Exception:
        return '?'

def parse_stdin():
    """Try to read session JSON from stdin. Returns (model, ctx_pct)."""
    try:
        raw = sys.stdin.read()
        if not raw.strip():
            return '?', None
        data = json.loads(raw)
        model = data.get('model', {}).get('id', '?')
        cw = data.get('context_window', {})
        used = cw.get('used_percentage')
        ctx_pct = int(used) if used is not None else None
        return model, ctx_pct
    except Exception:
        return '?', None

def main():
    model, ctx_pct = parse_stdin()
    branch = get_branch()

    parts = ['model:{}'.format(model), 'branch:{}'.format(branch)]
    if ctx_pct is not None:
        parts.append('ctx:{}%'.format(ctx_pct))

    sys.stdout.write(' | '.join(parts))

if __name__ == '__main__':
    main()
