using System;
using System.Security.Principal;
using System.Runtime.InteropServices;

namespace PoshCode.PowerLine
{
    static class NativeMethods {
        [DllImport("libc")]
        internal static extern uint getuid();

        [DllImport("libc")]
        internal static extern uint geteuid();
    }

    public static class State
    {
        [ThreadStatic] public static Alignment Alignment = Alignment.Left;
        [ThreadStatic] public static bool LastSuccess = true;

        public static bool Elevated = false;

        static State() {

            try {
                Elevated = WindowsIdentity.GetCurrent().Owner.IsWellKnown(WellKnownSidType.BuiltinAccountOperatorsSid);
            } catch {
                try {
                    Elevated = 0 == NativeMethods.getuid();
                } catch {}
            }
        }
    }
}
