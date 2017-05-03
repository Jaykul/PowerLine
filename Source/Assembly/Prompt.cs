using PoshCode.Pansies;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Text;
using System.Text.RegularExpressions;

namespace PowerLine
{
    public class Prompt
    {
        public static string ColorSeparator = "\u258C"; // ▌
        public static string ReverseColorSeparator = "\u2590"; // ▐
        public static string Separator = "\u25BA"; // ►
        public static string ReverseSeparator = "\u25C4"; // ◄
        public static string Branch = "\ue0a0"; // Branch symbol
        public static string Lock = "\ue0a2"; // Padlock
        public static string Gear = "\u26ef"; // The settings icon, I use it for debug
        public static string Power = "\u26a1"; // The Power lightning-bolt icon

        public List<Line> Lines { get; private set; }
        public ScriptBlock Title { get; set; }
        public bool SetCurrentDirectory { get; set; }
        public bool UseAnsiEscapes { get; set; }
        public bool RestoreVirtualTerminal { get; set; }
        public int PrefixLines { get; set; }

        public Prompt()
        {
            Lines = new List<Line>();
        }

        public Prompt(int prefixLines, params Line[] lines) : this()
        {
            PrefixLines = prefixLines;
            Lines.AddRange(lines);
        }

        public Prompt(params Line[] lines) : this()
        {
            Lines.AddRange(lines);
        }

        public Prompt(object[] lines) : this()
        {
            if (lines.First() is int)
            {
                PrefixLines = (int)lines.First();
                lines = lines.Skip(1).ToArray();
            }

            if (LanguagePrimitives.TryConvertTo(lines, out Line[] lns))
            {
                Lines.AddRange(lns);
                return;
            }

            if (LanguagePrimitives.TryConvertTo(lines, out Line ln))
            {
                Lines.Add(ln);
                return;
            }

            foreach (object line in lines)
            {
                Lines.Add(LanguagePrimitives.ConvertTo<Line>(line));
                continue;
            }
        }

        public override string ToString()
        {
            return ToString(Console.BufferWidth);
        }

        public string ToString(int width)
        {
            var output = new StringBuilder();

            // Move up to previous line(s)
            if (PrefixLines != 0)
            {
                output.Append(Entities.EscapeSequences["Esc"] + Math.Abs(PrefixLines) + "A");
            }

            output.Append(string.Join("\n", Lines.Select(l => l.ToString(width))));

            // reset, aagain?
            //output.Append(AnsiHelper.Foreground["Default"]);
            //output.Append(AnsiHelper.Background["Default"]);
            output.Append(Entities.EscapeSequences["Recall"]);

            return output.ToString();
        }

    }
}
