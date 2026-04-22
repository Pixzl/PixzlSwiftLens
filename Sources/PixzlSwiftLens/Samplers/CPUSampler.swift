import Foundation
import Darwin.Mach

struct CPUSampler {
    /// Returns total CPU usage of the current process across all threads as a percent (0...100 * cores).
    /// Clamped at 100 for display purposes.
    func samplePercent() -> Int {
        var threadList: thread_act_array_t?
        var threadCount: mach_msg_type_number_t = 0

        let result = task_threads(mach_task_self_, &threadList, &threadCount)
        guard result == KERN_SUCCESS, let threads = threadList else { return 0 }
        defer {
            let size = vm_size_t(Int(threadCount) * MemoryLayout<thread_t>.size)
            let address = vm_address_t(UInt(bitPattern: Int(bitPattern: threads)))
            vm_deallocate(mach_task_self_, address, size)
        }

        var totalUsage: Double = 0
        for i in 0..<Int(threadCount) {
            var threadInfo = thread_basic_info()
            var threadInfoCount = mach_msg_type_number_t(THREAD_INFO_MAX)
            let infoResult = withUnsafeMutablePointer(to: &threadInfo) {
                $0.withMemoryRebound(to: integer_t.self, capacity: Int(threadInfoCount)) {
                    thread_info(threads[i], thread_flavor_t(THREAD_BASIC_INFO), $0, &threadInfoCount)
                }
            }
            guard infoResult == KERN_SUCCESS else { continue }
            if threadInfo.flags & TH_FLAGS_IDLE == 0 {
                totalUsage += Double(threadInfo.cpu_usage) / Double(TH_USAGE_SCALE) * 100.0
            }
        }
        return min(100, Int(totalUsage))
    }
}
