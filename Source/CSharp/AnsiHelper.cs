using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Text;
using System.Text.RegularExpressions;

namespace PowerLine
{
    public static class AnsiHelper
    {
        public static string GetCode(this ConsoleColor? color, bool forBackground = false)
        {
            string colorCode = color == null ? "Default" : color.ToString();

            return forBackground ? Background[colorCode] : Foreground[colorCode];
        }

        public static Dictionary<string, string> Foreground = new Dictionary<string, string>
            {
                {"Clear",       "\u001B[39m"}, { "Default",  "\u001B[97m"},
                {"Black",       "\u001B[30m"}, { "DarkGray", "\u001B[90m"},
                {"DarkRed",     "\u001B[31m"}, { "Red",      "\u001B[91m"},
                {"DarkGreen",   "\u001B[32m"}, { "Green",    "\u001B[92m"},
                {"DarkYellow",  "\u001B[33m"}, { "Yellow",   "\u001B[93m"},
                {"DarkBlue",    "\u001B[34m"}, { "Blue",     "\u001B[94m"},
                {"DarkMagenta", "\u001B[35m"}, { "Magenta",  "\u001B[95m"},
                {"DarkCyan",    "\u001B[36m"}, { "Cyan",     "\u001B[96m"},
                {"Gray",        "\u001B[37m"}, { "White",    "\u001B[97m"}
            };

        public static Dictionary<string, string> Background = new Dictionary<string, string>
            {
                {"Clear",       "\u001B[49m"}, {"Default",  "\u001B[104m"},
                {"Black",       "\u001B[40m"}, {"DarkGray", "\u001B[100m"},
                {"DarkRed",     "\u001B[41m"}, {"Red",      "\u001B[101m"},
                {"DarkGreen",   "\u001B[42m"}, {"Green",    "\u001B[102m"},
                {"DarkYellow",  "\u001B[43m"}, {"Yellow",   "\u001B[103m"},
                {"DarkBlue",    "\u001B[44m"}, {"Blue",     "\u001B[104m"},
                {"DarkMagenta", "\u001B[45m"}, {"Magenta",  "\u001B[105m"},
                {"DarkCyan",    "\u001B[46m"}, {"Cyan",     "\u001B[106m"},
                {"Gray",        "\u001B[47m"}, {"White",    "\u001B[107m"}
            };


        public static string WriteAnsi(ConsoleColor? foreground, ConsoleColor? background, string value, bool clear = false)
        {
            var output = new StringBuilder();

            output.Append(background.GetCode(true));
            output.Append(foreground.GetCode());

            output.Append(value);
            if (clear)
            {
                output.Append(Background["Clear"]);
                output.Append(Foreground["Clear"]);
            }
            return output.ToString();
        }

        public static string GetString(object @object)
        {
            var scriptBlock = @object as ScriptBlock;
            return (string)LanguagePrimitives.ConvertTo(scriptBlock != null ? scriptBlock.Invoke() : @object, typeof(string));
        }

        static AnsiHelper()
        {
            Console.ResetColor();
            Foreground["Default"] = Foreground[Console.ForegroundColor >= 0 ? Console.ForegroundColor.ToString() : "White"]);
            Background["Default"] = Background[Console.BackgroundColor >= 0 ? Console.BackgroundColor.ToString() : "Black"]);
        }

        public struct EscapeCodes
        {
            public static readonly string Esc = "\u001B[";
            public static readonly string Clear = "\u001B[0m";
            public static readonly string PromptLocation = "\u001B[s";
            public static readonly string Recall = "\u001B[u";
        };
    }
}