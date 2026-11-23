// XPS 15 9520, BIOS 1.35.0. Loaded only by the Wi-Fi 6E test boot entry.
// The inspected CNVW EFUN method returns the 32-bit root GNVS field UHBS
// for Intel DSM function 3. No CNVW _INI exists in the inspected tables.
// Clear only the OEM UHB override; firmware regulatory rules still apply.
DefinitionBlock ("", "SSDT", 2, "LOCAL", "WIFI6E", 0x00000001)
{
    External (\UHBS, FieldUnitObj)
    External (\_SB.PC00.CNVW, DeviceObj)

    Method (\_SB.PC00.CNVW._INI, 0, Serialized)
    {
        Store (Zero, \UHBS)
    }
}
