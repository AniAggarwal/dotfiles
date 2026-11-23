.pragma library

// Geist: tabular figures (tnum) for the live numbers, and every symbol the bar uses.
var textFont = "Geist";
// Dune Rise is capitals only: the desktop clock and widget labels, nothing that needs reading at length.
var displayFont = "Dune Rise";
// Propo gives each glyph its own advance width, so icon-to-text gaps stay even.
var iconFont = "FiraCode Nerd Font Propo";

// All sizes are logical pixels.
var topGap = 2;
var sideInset = 8;
var barHeight = 24;
var pillGap = 6;
var pillPadding = 3;
var chipHeight = barHeight - 2 * pillPadding;
var barFontSize = 12;
var barIconSize = 13;
// Icons sit in a fixed-width box so glyphs of different widths keep gaps even.
var barIconBox = 16;
var trayIconSize = 14;
var popupFontSize = 13;
var popupGap = 6;

// Dropdowns share one surface per screen (PopupHost); it is this tall below the bar.
var popupMaxHeight = 620;
// Room around a dropdown for the overshoot of its morph.
var popupSlack = 18;

// Nested corners stay concentric: inner radius = outer radius - inset.
var radius = { pill: barHeight / 2, chip: chipHeight / 2, control: 8, card: 10, popup: 16 };
// Durations in ms. drop/morph/shrink are the dropdown opening and closing, swap is the move from
// one chip's dropdown to another's, hide is the bar leaving for a fullscreen window.
var motion = { fast: 120, normal: 180, meter: 450, drop: 170, open: 280, morph: 330, shrink: 200, swap: 260, hide: 130, glass: 320 };

// Frosted glass: background alpha over Hyprland's blur (layer rule "ani-bar-frost"). On battery,
// or with glass switched off, both are 1 and the rule's blur is turned off (see BarState).
var glass = { pill: 0.5, popup: 0.78 };

// Sampling periods in ms as [plugged in, on battery]; see BarState.every().
var cadence = {
    stats: [3000, 8000],          // CPU, memory, temperature and network counters for the bar
    statsOpen: [2000, 4000],      // the same while the system panel is open
    processes: [2, 4],            // seconds between top frames while the system panel is open
    disks: [60000, 120000],       // df while the system panel is open
    gpuBusy: [5000, 10000],       // nvidia-smi while the dGPU is working or the system panel is open
    gpuIdle: [30000, 60000],      // nvidia-smi while the dGPU is awake but idle
    idle: 30000                   // the bar's counters once nobody has touched the machine for a while
};
// Seconds without input before sampling slows down, and before it stops. hypridle locks and turns
// the screen off at 420 s; Keep Awake holds the screen on, so then sampling only slows down.
var idle = { slow: 120, stop: 430 };

// Severity thresholds for the stats readouts. 0 = normal, 1 = warning, 2 = critical.
var limits = {
    cpu: [80, 95],
    gpu: [90, 98],
    memory: [80, 92],
    temperature: [80, 90]
};

function severity(value, pair) {
    return value >= pair[1] ? 2 : value >= pair[0] ? 1 : 0;
}

function glyph(code) {
    return String.fromCodePoint(code);
}

// Material Design Icons from the Nerd Font. Code points are explicit so they are easy to audit.
var icons = {
    cpu: glyph(0xF0EE0),
    gpu: glyph(0xF08AE),
    memory: glyph(0xF061A),
    temperature: glyph(0xF050F),
    settings: glyph(0xF0493),
    music: glyph(0xF075A),
    play: glyph(0xF040A),
    pause: glyph(0xF03E4),
    previous: glyph(0xF04AE),
    shuffle: glyph(0xF049D),
    download: glyph(0xF01DA),
    upload: glyph(0xF0552),
    repeat: glyph(0xF0456),
    repeatOne: glyph(0xF0458),
    next: glyph(0xF04AD),
    calendar: glyph(0xF00ED),
    volumeMute: glyph(0xF0581),
    volumeLow: glyph(0xF057F),
    volumeMedium: glyph(0xF0580),
    volumeHigh: glyph(0xF057E),
    microphone: glyph(0xF036C),
    microphoneOff: glyph(0xF036D),
    brightness: glyph(0xF00E0),
    ethernet: glyph(0xF0200),
    wifiOff: glyph(0xF092E),
    wifi: [glyph(0xF092F), glyph(0xF091F), glyph(0xF0922), glyph(0xF0925), glyph(0xF0928)],
    // Same signal levels with a lock, shown while a VPN is up.
    wifiSecured: [glyph(0xF0921), glyph(0xF0921), glyph(0xF0924), glyph(0xF0927), glyph(0xF092A)],
    bluetoothAudio: glyph(0xF00B0),
    vpn: glyph(0xF0582),
    bluetoothOn: glyph(0xF00AF),
    bluetoothOff: glyph(0xF00B2),
    awakeOn: glyph(0xF0176),
    awakeOff: glyph(0xF0FAA),
    batteryCharging: glyph(0xF0084),
    batteryPlugged: glyph(0xF06A5),
    battery: [glyph(0xF008E), glyph(0xF007A), glyph(0xF007B), glyph(0xF007C), glyph(0xF007D),
        glyph(0xF007E), glyph(0xF007F), glyph(0xF0080), glyph(0xF0081), glyph(0xF0082), glyph(0xF0079)],
    lock: glyph(0xF033E),
    glass: glyph(0xF00B5),
    speed: glyph(0xF04C5),
    batteryLimit: glyph(0xF12A3),
    key: glyph(0xF0306),
    headphones: glyph(0xF02CB),
    back: glyph(0xF004D),
    submenu: glyph(0xF0142),
    check: glyph(0xF012C),
    suspend: glyph(0xF0904),
    hibernate: glyph(0xF0717),
    restart: glyph(0xF0709),
    powerOff: glyph(0xF0425),
    terminal: glyph(0xF018D),
    claude: glyph(0xF0674),
    robot: glyph(0xF06A9),
    inbox: glyph(0xF0687),
    webcam: glyph(0xF05A0),
    webcamOff: glyph(0xF1737),
    screenShare: glyph(0xF1483),
    bell: glyph(0xF009A),
    bellRing: glyph(0xF009E),
    trash: glyph(0xF0A7A),
    close: glyph(0xF0156)
};

function batteryIcon(percent) {
    return icons.battery[Math.max(0, Math.min(10, Math.round(percent / 10)))];
}

function volumeIcon(volume, muted) {
    if (muted || volume <= 0)
        return icons.volumeMute;
    return volume < 0.34 ? icons.volumeLow : volume < 0.67 ? icons.volumeMedium : icons.volumeHigh;
}

// Output device kind for the volume chip: "bluetooth", "headphones", "hdmi" or "speaker".
function outputKind(node) {
    const name = node?.name || "";
    const form = node?.properties?.["device.form-factor"] || node?.properties?.["device.form_factor"] || "";
    if (name.startsWith("bluez_output"))
        return "bluetooth";
    if (/head(phone|set)/.test(form) || /headphone/.test(node?.description?.toLowerCase() || ""))
        return "headphones";
    if (/hdmi|displayport/i.test(name))
        return "hdmi";
    return "speaker";
}

function wifiIcon(strength, secured) {
    return (secured ? icons.wifiSecured : icons.wifi)[Math.max(0, Math.min(4, Math.ceil(strength * 4)))];
}

// dunst pause levels, in cycle order. pause is the dunst pause level that selects it.
var dunstLevels = {
    all: { name: "All", icon: "󰂞", pause: 0 },
    reduced: { name: "Reduced", icon: "󰂚", pause: 25 },
    quiet: { name: "Quiet", icon: "󰂠", pause: 50 },
    critical: { name: "Critical only", icon: "󰵙", pause: 75 },
    none: { name: "None", icon: "󰂛", pause: 100 }
};
var dunstOrder = ["all", "reduced", "quiet", "critical", "none"];

function dunstLevel(pause) {
    return dunstOrder.find(function(key) { return dunstLevels[key].pause === pause; }) || "all";
}

function dunstIcon(level) {
    return (dunstLevels[level] || dunstLevels.all).icon;
}

function dunstName(level) {
    return (dunstLevels[level] || dunstLevels.all).name;
}

// "3 h", "2 d 4 h", "12 min"
function age(hours) {
    if (hours >= 48)
        return Math.floor(hours / 24) + " d";
    if (hours >= 24)
        return "1 d " + Math.floor(hours - 24) + " h";
    return hours >= 1 ? Math.floor(hours) + " h" : Math.max(1, Math.round(hours * 60)) + " min";
}

// "3 h 20 min", "2 d 4 h", "12 min"
function duration(seconds) {
    const minutes = Math.floor(seconds / 60);
    const days = Math.floor(minutes / 1440);
    const hours = Math.floor(minutes / 60) % 24;
    if (days > 0)
        return days + " d " + hours + " h";
    return hours > 0 ? hours + " h " + (minutes % 60) + " min" : (minutes % 60) + " min";
}

// "1.2 MB/s", "340 KB/s", "12 B/s"
function rate(bytes) {
    if (!(bytes >= 0))
        return "–";
    if (bytes >= 1048576)
        return (bytes / 1048576).toFixed(1) + " MB/s";
    if (bytes >= 1024)
        return Math.round(bytes / 1024) + " KB/s";
    return Math.round(bytes) + " B/s";
}

function clamp(value, low, high) {
    return Math.max(low, Math.min(high, value));
}
