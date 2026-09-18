#!/usr/bin/env python3
import json
import subprocess
import os
import glob

# Known prominent tray / background apps
KNOWN_TRAY = [
    {'id': 'vesktop', 'name': 'Discord', 'icon': '\uf392', 'color': '#5865f2', 'cmd': 'vesktop', 'match': ['vesktop', 'discord', 'webcord']},
    {'id': 'spotify', 'name': 'Spotify', 'icon': '\uf1bc', 'color': '#1db954', 'cmd': 'spotify', 'match': ['spotify']},
    {'id': 'steam', 'name': 'Steam', 'icon': '\uf1b6', 'color': '#2a475e', 'cmd': 'steam', 'match': ['steamwebhelper', 'steam']},
    {'id': 'zen', 'name': 'Zen Browser', 'icon': '\uf0ac', 'color': '#89b4fa', 'cmd': 'zen', 'match': ['zen-browser', 'zen']},
    {'id': 'ghostty', 'name': 'Ghostty Terminal', 'icon': '\uf120', 'color': '#cba6f7', 'cmd': 'ghostty', 'match': ['ghostty', 'com.mitchellh.ghostty']},
    {'id': 'obs', 'name': 'OBS Studio', 'icon': '\uf03d', 'color': '#eba0ac', 'cmd': 'obs', 'match': ['obs']},
    {'id': 'easyeffects', 'name': 'EasyEffects', 'icon': '\uf028', 'color': '#f9e2af', 'cmd': 'easyeffects', 'match': ['easyeffects']},
    {'id': 'qbittorrent', 'name': 'qBittorrent', 'icon': '\uf019', 'color': '#74c7ec', 'cmd': 'qbittorrent', 'match': ['qbittorrent']},
    {'id': 'telegram', 'name': 'Telegram', 'icon': '\uf2c6', 'color': '#24a1de', 'cmd': 'telegram-desktop', 'match': ['telegram-desktop', 'telegram']},
    {'id': 'antigravity-ide', 'name': 'Antigravity IDE', 'icon': '\uf121', 'color': '#74c7ec', 'cmd': 'antigravity-ide', 'match': ['antigravity-ide']},
]

def get_desktop_execs():
    execs = {}
    paths = glob.glob('/run/current-system/sw/share/applications/*.desktop') + \
            glob.glob(os.path.expanduser('~/.nix-profile/share/applications/*.desktop'))
    for p in paths:
        try:
            with open(p, 'r', errors='ignore') as f:
                name, exec_cmd, icon = '', '', ''
                for line in f:
                    if line.startswith('Name=') and not name:
                        name = line[5:].strip()
                    elif line.startswith('Exec=') and not exec_cmd:
                        cmd = line[5:].strip().split()[0]
                        exec_cmd = os.path.basename(cmd).lower()
                    elif line.startswith('Icon=') and not icon:
                        icon = line[5:].strip()
                if exec_cmd and name and not exec_cmd.startswith(('xwayland', 'systemd')):
                    execs[exec_cmd] = {'name': name, 'icon': icon}
        except:
            pass
    return execs

def main():
    desktop_execs = get_desktop_execs()
    my_pid = os.getpid()

    # 1. Active Hyprland clients
    try:
        clients = json.loads(subprocess.check_output(['hyprctl', 'clients', '-j']).decode())
    except:
        clients = []

    # Current workspace
    try:
        current_ws = json.loads(subprocess.check_output(['hyprctl', 'activeworkspace', '-j']).decode()).get('name', '1')
    except:
        current_ws = '1'

    # 2. User processes
    try:
        ps_raw = subprocess.check_output(['ps', '-u', os.environ.get('USER', ''), '-o', 'pid,comm,args']).decode().splitlines()
    except:
        ps_raw = []

    ignored_comms = {
        'python3', 'ps', 'grep', 'bash', 'sh', 'sd-pam', 'systemd', 'cat',
        'sleep', 'awk', 'sed', 'xwayland', 'wl-paste', 'hyprpaper', 'quickshell'
    }

    user_procs = []
    for line in ps_raw[1:]:
        parts = line.strip().split(None, 2)
        if len(parts) >= 3:
            pid = int(parts[0])
            comm = parts[1].lower()
            args = parts[2].lower()
            if pid != my_pid and comm not in ignored_comms:
                user_procs.append({'pid': pid, 'comm': comm, 'args': args})

    items = []
    matched_client_addrs = set()
    matched_proc_pids = set()

    # Process Known Tray Apps first
    for app in KNOWN_TRAY:
        client_match = None
        for c in clients:
            c_cls = (c.get('class') or '').lower()
            c_title = (c.get('title') or '').lower()
            if any(m in c_cls or m in c_title for m in app['match']):
                client_match = c
                matched_client_addrs.add(c.get('address'))
                break

        proc_match = None
        for p in user_procs:
            if any(m == p['comm'] or f'/{m}' in p['args'] or f' {m} ' in p['args'] for m in app['match']):
                proc_match = p
                matched_proc_pids.add(p['pid'])
                break

        if client_match:
            items.append({
                'id': app['id'],
                'name': app['name'],
                'icon': app['icon'],
                'color': app['color'],
                'cmd': app['cmd'],
                'appClass': client_match.get('class') or app['cmd'],
                'status': 'Open',
                'statusType': 'open',
                'hasWindow': True,
                'address': client_match.get('address') or '',
                'workspace': client_match.get('workspace', {}).get('name') or '1',
                'title': client_match.get('title') or app['name'],
                'pid': client_match.get('pid') or (proc_match['pid'] if proc_match else 0)
            })
        elif proc_match:
            items.append({
                'id': app['id'],
                'name': app['name'],
                'icon': app['icon'],
                'color': app['color'],
                'cmd': app['cmd'],
                'appClass': app['cmd'],
                'status': 'Background',
                'statusType': 'background',
                'hasWindow': False,
                'address': '',
                'workspace': '',
                'title': 'Running in background',
                'pid': proc_match['pid']
            })
        else:
            items.append({
                'id': app['id'],
                'name': app['name'],
                'icon': app['icon'],
                'color': app['color'],
                'cmd': app['cmd'],
                'appClass': app['cmd'],
                'status': 'Closed',
                'statusType': 'closed',
                'hasWindow': False,
                'address': '',
                'workspace': '',
                'title': 'Not running',
                'pid': 0
            })

    # Add other open Hyprland client windows not in known tray
    for c in clients:
        if c.get('address') not in matched_client_addrs:
            cls = c.get('class') or 'Application'
            items.append({
                'id': cls.lower(),
                'name': cls,
                'icon': '\uf2d0',
                'color': '#89b4fa',
                'cmd': cls.lower(),
                'appClass': cls,
                'status': 'Open',
                'statusType': 'open',
                'hasWindow': True,
                'address': c.get('address') or '',
                'workspace': c.get('workspace', {}).get('name') or '1',
                'title': c.get('title') or cls,
                'pid': c.get('pid') or 0
            })

    # Add any other running background desktop applications
    seen_comms = set()
    for p in user_procs:
        if p['pid'] not in matched_proc_pids:
            comm = p['comm']
            if comm in desktop_execs and comm not in seen_comms:
                seen_comms.add(comm)
                meta = desktop_execs[comm]
                items.append({
                    'id': comm,
                    'name': meta['name'],
                    'icon': '\uf085',
                    'color': '#f9e2af',
                    'cmd': comm,
                    'appClass': comm,
                    'status': 'Background',
                    'statusType': 'background',
                    'hasWindow': False,
                    'address': '',
                    'workspace': '',
                    'title': 'Running in background',
                    'pid': p['pid']
                })

    # Sort: Open first, then Background, then Closed
    status_order = {'open': 0, 'background': 1, 'closed': 2}
    items.sort(key=lambda x: (status_order.get(x['statusType'], 3), x['name'].lower()))

    output = {
        'currentWs': current_ws,
        'totalRunning': sum(1 for x in items if x['statusType'] in ('open', 'background')),
        'openCount': sum(1 for x in items if x['statusType'] == 'open'),
        'bgCount': sum(1 for x in items if x['statusType'] == 'background'),
        'items': items
    }

    print(json.dumps(output))

if __name__ == '__main__':
    main()
