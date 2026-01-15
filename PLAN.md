# BarBar - macOS Menu Bar Toolkit

## Tavoite
Pivotoida DiskTrend "BarBar"-nimiseksi moduuliseksi menu bar -työkalupakiksi ja julkaista App Storessa.

---

## MVP-moduulit

| Moduuli | Kuvaus | Prioriteetti |
|---------|--------|--------------|
| **System Monitor** | CPU, RAM, Disk -seuranta (laajennettu DiskTrend) | 1 |
| **Keep-Awake** | Estää Macin nukahtamisen (Lungo-tyyli) | 2 |
| **Menu Bar Organizer** | Ikonien hallinta (rajoitettu App Store -versiossa) | 3 |

---

## Projektirakenne

```
BarBar/
├── Core/
│   ├── App/
│   │   ├── BarBarApp.swift           # @main entry point
│   │   └── AppState.swift
│   ├── Module/
│   │   ├── ModuleProtocol.swift      # Moduulirajapinta
│   │   └── ModuleManager.swift       # Moduulien hallinta
│   ├── Settings/
│   │   ├── SettingsView.swift
│   │   └── SettingsWindowController.swift
│   ├── UI/
│   │   ├── MainPopoverView.swift     # Tab-pohjainen popover
│   │   └── MenuBarView.swift         # Dynaaminen menu bar -ikoni
│   └── Resources/
│       └── Localization/
│
├── Modules/
│   ├── SystemMonitor/
│   │   ├── SystemMonitorModule.swift
│   │   ├── Services/
│   │   │   ├── CPUMonitor.swift      # host_statistics()
│   │   │   ├── RAMMonitor.swift      # vm_statistics64
│   │   │   └── DiskMonitor.swift     # FileManager API
│   │   └── Views/
│   │
│   ├── KeepAwake/
│   │   ├── KeepAwakeModule.swift
│   │   ├── Services/
│   │   │   └── PowerManager.swift    # IOPMAssertionCreate
│   │   └── Views/
│   │
│   └── MenuBarOrganizer/
│       ├── MenuBarOrganizerModule.swift
│       └── Views/
│
└── project.yml
```

---

## Toteutusvaiheet

### Vaihe 1: Projektin uudelleenjärjestely
- [ ] Luo `Core/` ja `Modules/` kansiorakenne
- [ ] Siirrä DiskTrend-koodi → `Modules/SystemMonitor/`
- [ ] Luo `ModuleProtocol.swift` moduulirajapinta
- [ ] Luo `ModuleManager.swift` moduulien hallintaan
- [ ] Refaktoroi `DiskTrendApp.swift` → `BarBarApp.swift`

### Vaihe 2: System Monitor -laajennus
- [ ] Implementoi `CPUMonitor.swift` (host_statistics API)
- [ ] Implementoi `RAMMonitor.swift` (vm_statistics64 API)
- [ ] Päivitä DiskMonitor noudattamaan ModuleProtocol
- [ ] Luo yhdistetty SystemMonitorView (CPU/RAM/Disk tabseina)

### Vaihe 3: Keep-Awake -moduuli
- [ ] Implementoi `PowerManager.swift` (IOPMAssertionCreate/Release)
- [ ] Luo KeepAwakeModule + KeepAwakeView
- [ ] Lisää duration presetit (15min, 30min, 1h, 2h, indefinite)
- [ ] Lisää display sleep vs system sleep -valinnat

### Vaihe 4: Menu Bar Organizer
- [ ] Määritä realistinen toiminnallisuus (App Store -rajoitukset)
- [ ] Informatiivinen näkymä + ohjeistus

### Vaihe 5: Unified UI
- [ ] Luo `MainPopoverView` tab-navigaatiolla
- [ ] Päivitä `SettingsView` moduulikohtaisilla välilehdillä
- [ ] Luo dynaaminen `MenuBarView`

### Vaihe 6: App Store -valmistelu
- [ ] Ota sandbox käyttöön
- [ ] Testaa sandbox-yhteensopivuus
- [ ] Päivitä Bundle ID: `com.barbar.app`

---

## Tekniset yksityiskohdat

### ModuleProtocol
```swift
protocol BarBarModule: ObservableObject {
    static var moduleId: String { get }
    static var moduleName: String { get }
    static var moduleIcon: String { get }

    var isEnabled: Bool { get set }
    var statusSummary: String { get }

    func onActivate()
    func onDeactivate()

    associatedtype ContentView: View
    func makeContentView() -> ContentView
}
```

### CPUMonitor
- `host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, ...)`
- Laskee user/system/idle CPU-käytön
- Päivitysväli: 2s

### RAMMonitor
- `host_statistics64(mach_host_self(), HOST_VM_INFO64, ...)`
- Näyttää: active, wired, compressed, free
- "Used" = active + wired + compressed

### PowerManager (Keep-Awake)
- `IOPMAssertionCreateWithName()` - aktivoi
- `IOPMAssertionRelease()` - deaktivoi
- Moodit: `PreventUserIdleDisplaySleep`, `PreventUserIdleSystemSleep`
- **Toimii App Store sandboxissa**

---

## App Store -yhteensopivuus

| Toiminto | Sandbox-tuki | Huomio |
|----------|--------------|--------|
| CPU/RAM monitoring | Toimii | Mach API sallittu |
| Disk monitoring | Toimii | FileManager API |
| Keep-Awake (IOKit) | Toimii | IOPMAssertion sallittu |
| SwiftData | Toimii | App container |
| Launch at login | Toimii | SMAppService |
| Menu bar icon control | Ei toimi | Ei pääsyä muihin ikoneihin |

---

## Kriittiset tiedostot (migraatio)

| Nykyinen | Uusi sijainti |
|----------|---------------|
| `DiskTrendApp.swift` | `Core/App/BarBarApp.swift` |
| `DiskMonitor.swift` | `Modules/SystemMonitor/Services/DiskMonitor.swift` |
| `PopoverView.swift` | `Core/UI/MainPopoverView.swift` + moduulikohtaiset |
| `SettingsView.swift` | `Core/Settings/SettingsView.swift` |
| `project.yml` | Päivitetään uudella rakenteella |

---

## Verifiointi

1. `xcodebuild -scheme BarBar -configuration Debug build`
2. Sandbox-testaus: Aja sandboxattuna, varmista CPU/RAM/Disk toimii
3. Keep-Awake: Aktivoi → tarkista `pmset -g assertions`
4. Menu bar UI: Testaa tab-navigaatio ja moduulien vaihtaminen
