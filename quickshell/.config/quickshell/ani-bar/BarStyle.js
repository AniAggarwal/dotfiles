.pragma library

var textFont = "Adwaita Sans";
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

// Nested corners stay concentric: inner radius = outer radius - inset.
var radius = { pill: barHeight / 2, chip: chipHeight / 2, control: 8, card: 10, popup: 16 };
var motion = { fast: 120, normal: 180, meter: 450 };

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
    next: glyph(0xF04AD),
    previous: glyph(0xF04AE),
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

// dunst pause levels, in cycle order.
var dunstLevels = {
    all: { name: "All", icon: "󰂞" },
    reduced: { name: "Reduced", icon: "󰂚" },
    quiet: { name: "Quiet", icon: "󰂠" },
    critical: { name: "Critical only", icon: "󰵙" },
    none: { name: "None", icon: "󰂛" }
};

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
