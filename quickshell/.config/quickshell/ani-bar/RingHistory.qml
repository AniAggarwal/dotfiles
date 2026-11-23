import QtQuick

// Fixed-size sample history. push() overwrites the oldest sample in place, so a tick allocates
// nothing; views repaint when revision changes.
QtObject {
    id: history

    property int capacity: 60
    readonly property var samples: new Float32Array(capacity)
    property int count: 0
    property int head: 0
    property int revision: 0

    function push(value) {
        samples[head] = value;
        head = (head + 1) % capacity;
        if (count < capacity)
            count++;
        revision++;
    }

    // index 0 is the oldest sample, count - 1 the newest.
    function at(index) {
        return samples[(head - count + index + capacity) % capacity];
    }

    function peak() {
        let highest = 0;
        for (let i = 0; i < count; i++)
            highest = Math.max(highest, samples[i]);
        return highest;
    }

    function clear() {
        count = 0;
        head = 0;
        revision++;
    }
}
