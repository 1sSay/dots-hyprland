"""Read CPU/GPU hwmon sensors without depending on unstable hwmon numbers."""

import json
import time
from pathlib import Path


def read_text(path):
    try:
        return path.read_text().strip()
    except OSError:
        return ""


def temperatures(hwmon_root=Path("/sys/class/hwmon")):
    readings = {"cpu": [], "gpu": []}
    for device in hwmon_root.glob("hwmon*"):
        driver = read_text(device / "name")
        if driver in ("k10temp", "zenpower", "coretemp"):
            kind = "cpu"
            preferred = ("Tctl", "Tdie", "Package id 0")
        elif driver in ("amdgpu", "nouveau", "nvidia"):
            kind = "gpu"
            preferred = ("edge", "GPU core", "temp1")
        else:
            continue
        candidates = []
        for sensor in device.glob("temp*_input"):
            try:
                value = int(read_text(sensor)) / 1000
            except ValueError:
                continue
            if not 0 < value < 150:
                continue
            label = read_text(sensor.with_name(sensor.name.replace("_input", "_label")))
            priority = preferred.index(label) if label in preferred else len(preferred)
            candidates.append((priority, value))
        if candidates:
            priority = min(item[0] for item in candidates)
            readings[kind].extend(value for rank, value in candidates if rank == priority)
    return {kind: max(values) if values else None for kind, values in readings.items()}


def fan_rpms(status=Path("/run/asus-fan-rpm/status.json"), now=None):
    """Read unprivileged telemetry; never show a stopped collector's old RPM."""
    try:
        data = json.loads(status.read_text())
        age = (time.time() if now is None else now) - data["updated_at"]
        values = data["fan_rpms"]
        if not 0 <= age <= 10 or not isinstance(values, list) or len(values) != 2:
            return [None, None]
        if any(value is not None and (type(value) is not int or not 0 <= value <= 20000)
               for value in values):
            return [None, None]
        return values
    except (OSError, ValueError, KeyError, TypeError):
        return [None, None]


if __name__ == "__main__":
    print(json.dumps({**temperatures(), "fan_rpms": fan_rpms()}))
