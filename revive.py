import threading
import time
import os
import subprocess
import sys

import tkinter as tk
from tkinter import messagebox

if getattr(sys, "frozen", False):
    BASE_DIR = os.path.dirname(sys.executable)
else:
    BASE_DIR = os.path.dirname(os.path.abspath(__file__))

DRIVER_PATH = r"C:\Program Files\Nefarius Software Solutions\ViGEm Bus Driver"
INSTALLER = os.path.join(BASE_DIR, "Lib", "ViGEmBus_1.22.0_x64_x86_arm64.exe")

if not os.path.exists(DRIVER_PATH):
    if not os.path.exists(INSTALLER):
        messagebox.showerror(
            "Installer Missing",
            f"ViGEm installer not found at:\n{INSTALLER}"
        )

        sys.exit(1)

    root = tk.Tk()
    root.withdraw()

    messagebox.showinfo(
        "Installing ViGEm Driver",
        "ViGEm Bus driver not found. The installer will run."
    )

    try:
        subprocess.run([INSTALLER], check=True)
    except Exception as e:
        messagebox.showerror("Installation Failed", f"Failed to run ViGEm installer:\n{e}")

        sys.exit(1)

import configparser

CONFIG_FILE = "settings.ini"
DEFAULT_TOGGLE_KEY = "5"

config = configparser.ConfigParser()

if not os.path.exists(CONFIG_FILE):
    config["Settings"] = {"ToggleKey": DEFAULT_TOGGLE_KEY, "DeveloperMode": "False"}
    with open(CONFIG_FILE, "w") as f:
        config.write(f)

config.read(CONFIG_FILE)
TOGGLE_KEY = config.get("Settings", "ToggleKey", fallback=DEFAULT_TOGGLE_KEY)
DEVELOPER_MODE = config.getboolean("Settings", "DeveloperMode", fallback=False)

import vgamepad as vg
import keyboard

CONTROLLER_DELAY = 5 if DEVELOPER_MODE else 10
REVIVE_DELAY = 5 if DEVELOPER_MODE else 19.25
TOTAL_TIME = 10 if DEVELOPER_MODE else 29.25
REVIVE_TIME = 1.6
TICK_TIME = 0.025

active = False
revived = False
now = 0
next_press_time = 0
running = True

gamepad = vg.VX360Gamepad()

joystick_input = {"x_target": 0.0, "y_target": 0.0, "x_current": 0.0, "y_current": 0.0}
reset_joystick = False

state_lock = threading.Lock()

def press_button(button, hold=TICK_TIME):
    if not running:
        return
    gamepad.press_button(button)
    gamepad.update()

    time.sleep(hold)

    gamepad.release_button(button)
    gamepad.update()


def move_joystick(step=0.2):
    global reset_joystick

    if not running or not root.winfo_exists():
        return

    with state_lock:
        if reset_joystick or not active:
            joystick_input["x_current"] = 0.0
            joystick_input["y_current"] = 0.0
            joystick_input["x_target"] = 0.0
            joystick_input["y_target"] = 0.0
            
            reset_joystick = False

        x_smooth = joystick_input["x_current"] + (joystick_input["x_target"] - joystick_input["x_current"]) * step
        y_smooth = joystick_input["y_current"] + (joystick_input["y_target"] - joystick_input["y_current"]) * step

        x_smooth = max(-1.0, min(1.0, x_smooth))
        y_smooth = max(-1.0, min(1.0, y_smooth))

        joystick_input["x_current"] = x_smooth
        joystick_input["y_current"] = y_smooth

    gamepad.right_joystick_float(x_smooth, y_smooth)
    gamepad.update()

def toggle_revive():
    global active, now, next_press_time, revived, reset_joystick

    with state_lock:
        active = not active

        if active:
            now = time.time()
            next_press_time = now + CONTROLLER_DELAY
            revived = False
        else:
            if root.winfo_exists():
                toggle_btn.config(text="Enable", bg="#b22222")

            reset_joystick = True

def keyboard_thread():
    keyboard.on_press_key(TOGGLE_KEY, lambda e: toggle_revive())

    while running and root.winfo_exists():
        x, y = 0.0, 0.0
        if active:
            if keyboard.is_pressed("up") or keyboard.is_pressed("i"):
                y = 1.0
            elif keyboard.is_pressed("down") or keyboard.is_pressed("k"):
                y = -1.0
            if keyboard.is_pressed("left") or keyboard.is_pressed("j"):
                x = -1.0
            elif keyboard.is_pressed("right") or keyboard.is_pressed("l"):
                x = 1.0

        with state_lock:
            joystick_input["x_target"] = x
            joystick_input["y_target"] = y

        time.sleep(TICK_TIME)

def revive_thread():
    global active, revived, now

    while running and root.winfo_exists():
        if active:
            start_time = time.time()

            revived = False

            while active and root.winfo_exists():
                elapsed = time.time() - start_time

                if CONTROLLER_DELAY <= elapsed < REVIVE_DELAY:
                    press_button(vg.XUSB_BUTTON.XUSB_GAMEPAD_X)

                    time.sleep(1)

                elif REVIVE_DELAY <= elapsed < TOTAL_TIME:
                    if not revived:
                        press_button(vg.XUSB_BUTTON.XUSB_GAMEPAD_X, hold=REVIVE_TIME)

                        revived = True

                    press_button(vg.XUSB_BUTTON.XUSB_GAMEPAD_RIGHT_SHOULDER)

                move_joystick()

                time.sleep(TICK_TIME)

                if elapsed >= TOTAL_TIME:
                    with state_lock:
                        active = False

                        if root.winfo_exists():
                            toggle_btn.config(text="Enable", bg="#b22222")

                        reset_joystick = True

                    move_joystick(step=1.0)

                    break
        else:
            move_joystick()

            time.sleep(TICK_TIME)

def ui_update_loop():
    if not running or not root.winfo_exists():
        return
    
    with state_lock:
        if active:
            elapsed = time.time() - now

            toggle_btn.config(text=f"Active: {elapsed:.2f}s", bg="#228B22", fg="#ffffff")
        else:
            toggle_btn.config(text="Enable", bg="#b22222", fg="#ffffff")

    root.after(int(TICK_TIME*1000), ui_update_loop)

def cleanup():
    global running

    running = False

    try:
        gamepad.reset()
    except:
        pass
    try:
        if root.winfo_exists():
            root.destroy()
    except:
        pass

import atexit

atexit.register(cleanup)

try:
    root = tk.Tk()
    root.title("post-descent")
    root.geometry("400x200")
    root.resizable(False, False)
    root.configure(bg="#1e1e1e")

    toggle_btn = tk.Button(
        root,
        text="Enable",
        font=("Arial", 18, "bold"),
        width=20,
        height=3,
        bg="#2e2e2e",
        fg="#eeeeee",
        activebackground="#3e3e3e",
        activeforeground="#ffffff",
        relief="flat"
    )
    toggle_btn.pack(pady=20)

    key_label = tk.Label(
        root,
        text=f"Toggle Key: {TOGGLE_KEY}",
        bg="#1e1e1e",
        fg="#cccccc",
        font=("Arial", 12)
    )
    key_label.pack(pady=5)

    toggle_btn.config(command=toggle_revive)

    threading.Thread(target=keyboard_thread, daemon=True).start()
    threading.Thread(target=revive_thread, daemon=True).start()

    ui_update_loop() 
    root.mainloop()

except Exception as e:
    print(f"Fatal error: {e}")

finally:
    cleanup()
    sys.exit(0)
