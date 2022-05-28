using System;
using System.Security.Principal;
using System.Runtime.InteropServices;

namespace PoshCode.PowerLine
{
    static class NativeMethods
    {
        [DllImport("libc")]
        internal static extern uint getuid();

        [DllImport("libc")]
        internal static extern uint geteuid();
    }

    public static class State
    {
        [ThreadStatic] private static Alignment alignment = Alignment.Left;
        [ThreadStatic] private static bool lastSuccess = true;

        public static bool Elevated { get; }

        public static Alignment Alignment { get => alignment; set => alignment = value; }

        public static bool LastSuccess { get => lastSuccess; set => lastSuccess = value; }

        static State()
        {

            try
            {
                Elevated = WindowsIdentity.GetCurrent().Owner.IsWellKnown(WellKnownSidType.BuiltinAccountOperatorsSid);
            }
            catch
            {
                try
                {
                    Elevated = 0 == NativeMethods.getuid();
                }
                catch {}
            }
        }
    }
}
