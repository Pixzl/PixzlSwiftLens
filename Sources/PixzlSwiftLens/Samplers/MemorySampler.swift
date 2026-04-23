import Foundation
import Darwin.Mach

struct MemorySampler {
    /// Returns the process's physical footprint in MB — the same metric iOS Jetsam
    /// uses to decide which processes to terminate under memory pressure, and what
    /// Xcode's Memory Graph displays. `phys_footprint` includes dirty + compressed
    /// pages, unlike the older `resident_size` which only counts resident pages.
    func sampleMB() -> Int {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return 0 }
        return Int(info.phys_footprint / (1024 * 1024))
    }
}
