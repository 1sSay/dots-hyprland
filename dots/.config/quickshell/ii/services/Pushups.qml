pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import qs.services
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Persistent push-up counter keyed by local calendar date.
 * The data is deliberately kept separate from shell state, so old training
 * days remain available after Quickshell and Hyprland are restarted.
 */
Singleton {
    id: root

    property string filePath: `${Directories.state}/pushups.json`
    property var entries: ({})
    property var now: new Date()
    readonly property string todayKey: root.dateKey(root.now)
    readonly property int today: root.countFor(root.todayKey)
    readonly property int weekTotal: root.totalForDates(root.weekDates())
    readonly property int monthTotal: root.totalForDates(root.monthDates())
    readonly property string monthLabel: Qt.locale().toString(root.now, "MMMM yyyy")

    function dateKey(date) {
        const year = date.getFullYear();
        const month = String(date.getMonth() + 1).padStart(2, "0");
        const day = String(date.getDate()).padStart(2, "0");
        return `${year}-${month}-${day}`;
    }

    function countFor(key) {
        return Number(root.entries[key] || 0);
    }

    function datesBetween(first, last) {
        const dates = [];
        const current = new Date(first);
        while (current <= last) {
            dates.push(new Date(current));
            current.setDate(current.getDate() + 1);
        }
        return dates;
    }

    function weekDates() {
        const first = new Date(root.now);
        const offset = (first.getDay() + 6) % 7; // Monday is the first day.
        first.setHours(0, 0, 0, 0);
        first.setDate(first.getDate() - offset);
        const last = new Date(first);
        last.setDate(last.getDate() + 6);
        return root.datesBetween(first, last);
    }

    function monthDates() {
        const first = new Date(root.now.getFullYear(), root.now.getMonth(), 1);
        const last = new Date(root.now.getFullYear(), root.now.getMonth() + 1, 0);
        return root.datesBetween(first, last);
    }

    function totalForDates(dates) {
        return dates.reduce((total, date) => total + root.countFor(root.dateKey(date)), 0);
    }

    function weekEntries() {
        return root.weekDates().map(date => ({
            "label": Qt.locale().toString(date, "ddd"),
            "date": date,
            "count": root.countFor(root.dateKey(date)),
            "today": root.dateKey(date) === root.todayKey,
        }));
    }

    function add() {
        root.now = new Date();
        root.setCount(root.todayKey, root.today + 1);
    }

    function setCount(key, count) {
        const updatedEntries = Object.assign({}, root.entries);
        updatedEntries[key] = Math.max(0, Number(count) || 0);
        root.entries = updatedEntries;
        pushupsFile.setText(JSON.stringify(root.entries));
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    Component.onCompleted: pushupsFile.reload()

    FileView {
        id: pushupsFile
        path: Qt.resolvedUrl(root.filePath)

        onLoaded: {
            try {
                const savedEntries = JSON.parse(pushupsFile.text());
                root.entries = savedEntries && typeof savedEntries === "object" && !Array.isArray(savedEntries) ? savedEntries : {};
            } catch (error) {
                console.warn("[Push-ups] Failed to read saved counter:", error);
                root.entries = {};
            }
        }
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                pushupsFile.setText(JSON.stringify(root.entries));
            } else {
                console.warn("[Push-ups] Failed to load counter:", error);
            }
        }
    }
}
