# -*- mode: python ; coding: utf-8 -*-
# PyInstaller build spec for YiQQ-Rcon
# Usage:  pyinstaller build.spec

block_cipher = None

a = Analysis(
    ['main.py'],
    pathex=['.'],
    binaries=[],
    datas=[
        ('assets/fonts', 'assets/fonts'),
        ('assets/i18n', 'assets/i18n'),
        ('assets/avatar.png', 'assets'),
        ('qml', 'qml'),
    ],
    hiddenimports=[
        'socks',
        'PySide6.QtSvg',
        'PySide6.QtQuick',
        'PySide6.QtQuickControls2',
        'PySide6.QtQuickLayouts',
        'PySide6.QtQuickShapes',
        'PySide6.QtQuickDialogs2',
        'PySide6.QtQuickTemplates2',
        'PySide6.QtQml',
    ],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[
        'tkinter',
        'unittest',
        'pydoc',
        'doctest',
        'pdb',
    ],
    noarchive=False,
)

pyz = PYZ(a.pure)

exe = EXE(
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,
    name='YiQQ-Rcon',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=False,
    console=False,
    icon='assets/app.ico',
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
)

coll = COLLECT(
    exe,
    a.binaries,
    a.zipfiles,
    a.datas,
    strip=False,
    upx=False,
    upx_exclude=[],
    name='YiQQ-Rcon',
)
