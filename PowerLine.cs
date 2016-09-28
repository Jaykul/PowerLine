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
                {"Clear",       "\u001B[39m"}, {"Default",  "\u001B[97m"},
                {"Black",       "\u001B[30m"}, {"DarkGray", "\u001B[90m"},
                {"DarkRed",     "\u001B[31m"}, {"Red",      "\u001B[91m"},
                {"DarkGreen",   "\u001B[32m"}, {"Green",    "\u001B[92m"},
                {"DarkYellow",  "\u001B[33m"}, {"Yellow",   "\u001B[93m"},
                {"DarkBlue",    "\u001B[34m"}, {"Blue",     "\u001B[94m"},
                {"DarkMagenta", "\u001B[35m"}, {"Magenta",  "\u001B[95m"},
                {"DarkCyan",    "\u001B[36m"}, {"Cyan",     "\u001B[96m"},
                {"Gray",        "\u001B[37m"}, {"White",    "\u001B[97m"}
            };

        public static Dictionary<string, string> Background = new Dictionary<string, string>
            {
                {"Clear",       "\u001B[49m"}, {"Default",  "\u001B[40m"},
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

            var color = Console.ForegroundColor >= 0 ? Console.ForegroundColor.ToString() : "White";
            Foreground["Default"] = Foreground[color];

            color = Console.BackgroundColor >= 0 ? Console.BackgroundColor.ToString() : "White";
            Background["Default"] = Background[color];
        }

        public struct EscapeCodes
        {
            public static readonly string Esc = "\u001B[";
            public static readonly string Clear = "\u001B[0m";
            public static readonly string PromptLocation = "\u001B[s";
            public static readonly string Recall = "\u001B[u";
        };
    }
    public class Block
    {
        private string _text;
        /// <summary>
        /// Gets or sets the object. The Object will be converted to string when it's set, and this property always returns a string.
        /// </summary>
        /// <value>A string</value>
        public object Object
        {
            get
            {
                return _text;
            }
            set
            {
                _text = (string)LanguagePrimitives.ConvertTo(value, typeof(string));

                // If there's actually no output, report a negative length to ignore this block
                if (string.IsNullOrEmpty(_text))
                {
                    Length = -1;
                }
                else
                {
                    // The Length is measured without escape sequences (Esc + non-letters + any letter)
                    Length = _escapeCode.Replace(_text, "").Length;
                }
            }
        }
        private Regex _escapeCode = new Regex("\u001B\\P{L}+\\p{L}", RegexOptions.Compiled);

        /// <summary>
        /// Gets or Sets the background color for the block
        /// </summary>
        public ConsoleColor? BackgroundColor { get; set; }

        /// <summary>
        /// Gets or Sets the foreground color for the block
        /// </summary>
        public ConsoleColor? ForegroundColor { get; set; }

        /// <summary>
        /// Gets the length of the text representation (without ANSI escape sequences).
        /// </summary>
        public int Length { get; private set; }

        /// <summary>
        /// This constructor is here so we can allow partial matches to the property names.
        /// </summary>
        /// <param name="values"></param>
        public Block(IDictionary values) : this()
        {
            foreach (string key in values.Keys)
            {
                var pattern = "^" + Regex.Escape(key);
                if ("bg".Equals(key, StringComparison.OrdinalIgnoreCase) || Regex.IsMatch("BackgroundColor", pattern, RegexOptions.IgnoreCase))
                {
                    BackgroundColor = (ConsoleColor)Enum.Parse(typeof(ConsoleColor), values[key].ToString(), true);
                }
                else if ("fg".Equals(key, StringComparison.OrdinalIgnoreCase) || Regex.IsMatch("ForegroundColor", pattern, RegexOptions.IgnoreCase))
                {
                    ForegroundColor = (ConsoleColor)Enum.Parse(typeof(ConsoleColor), values[key].ToString(), true);
                }
                else if (Regex.IsMatch("text", pattern, RegexOptions.IgnoreCase) || Regex.IsMatch("Content", pattern, RegexOptions.IgnoreCase) || Regex.IsMatch("Object", pattern, RegexOptions.IgnoreCase))
                {
                    Object = values[key];
                }
                //else if (Regex.IsMatch("Clear", pattern, RegexOptions.IgnoreCase))
                //{
                //    Clear = (bool)values[key];
                //}
                else
                {
                    throw new ArgumentException("Unknown key '" + key + "' in hashtable. Allowed values are BackgroundColor, ForegroundColor, and Object (also called Content or Text)");
                }
            }
        }
        // Make sure we can output plain text
        public Block(string text) : this()
        {
            Object = text;
        }

        // Make sure we support the default ctor
        public Block() { Length = -1; }

        public override string ToString()
        {
            // If there's nothing but escape codes, don't bother outputting new colors
            if (Length == 0)
            {
                return (string)Object;
            }
            return AnsiHelper.WriteAnsi(ForegroundColor, BackgroundColor, (string)Object);
        }

        // override object.Equals
        public override bool Equals(object obj)
        {
            if (obj == null || GetType() != obj.GetType())
            {
                // Console.WriteLine(GetType().FullName + " is not " + obj.GetType().FullName);
                return false;
            }

            var other = obj as Block;

            return other != null && (Object == other.Object && ForegroundColor == other.ForegroundColor && BackgroundColor == other.BackgroundColor);
        }

        // override object.GetHashCode
        public override int GetHashCode()
        {
            return Object.GetHashCode();
        }
    }

    /// <summary>
    /// The block factory is a Block which supports scriptblocks that output blocks ...
    /// </summary>
    public class BlockFactory
    {
        /// <summary>
        /// Gets or Sets the background color for the block
        /// </summary>
        public ConsoleColor? DefaultBackgroundColor { get; set; }

        /// <summary>
        /// Gets or Sets the foreground color for the block
        /// </summary>
        public ConsoleColor? DefaultForegroundColor { get; set; }

        /// <summary>
        /// Gets or Sets the object to be rendered.
        /// Can be any object, but with particular support for nested lists of objects, blocks, or ScriptBlocks which output them.
        /// </summary>
        public object Object { get; set; }

        /// <summary>
        /// This constructor is here so we can allow partial matches to the property names.
        /// </summary>
        /// <param name="values"></param>
        public BlockFactory(IDictionary values)
        {
            foreach (string key in values.Keys)
            {
                var pattern = "^" + Regex.Escape(key);
                if ("bg".Equals(key, StringComparison.OrdinalIgnoreCase) || Regex.IsMatch("BackgroundColor", pattern, RegexOptions.IgnoreCase) || Regex.IsMatch("DefaultBackgroundColor", pattern, RegexOptions.IgnoreCase))
                {
                    DefaultBackgroundColor = (ConsoleColor)Enum.Parse(typeof(ConsoleColor), values[key].ToString(), true);
                }
                else if ("fg".Equals(key, StringComparison.OrdinalIgnoreCase) || Regex.IsMatch("ForegroundColor", pattern, RegexOptions.IgnoreCase) || Regex.IsMatch("DefaultForegroundColor", pattern, RegexOptions.IgnoreCase))
                {
                    DefaultForegroundColor = (ConsoleColor)Enum.Parse(typeof(ConsoleColor), values[key].ToString(), true);
                }
                else if (Regex.IsMatch("text", pattern, RegexOptions.IgnoreCase) || Regex.IsMatch("Content", pattern, RegexOptions.IgnoreCase) || Regex.IsMatch("Object", pattern, RegexOptions.IgnoreCase))
                {
                    Object = values[key];
                }
                //else if (Regex.IsMatch("Clear", pattern, RegexOptions.IgnoreCase))
                //{
                //    Clear = (bool)values[key];
                //}
                else
                {
                    throw new ArgumentException("Unknown key '" + key + "' in " + values.GetType().Name + ". Allowed values are BackgroundColor (or bg), ForegroundColor (or fg), and Object (also called Content or Text)");
                }
            }
        }

        public BlockFactory(Block block)
        {
            Object = block;
        }

        public BlockFactory(params Block[] blocks)
        {
            Object = blocks;
        }

        public Block[] GetBlocks()
        {
            // There are four allowed values:
            // 1. A scriptblock, which outputs one of the other possibilities
            // 2. One or more blocks
            // 3. Things we'll convert to text
            var cache = Object;
            Block[] blocks;

            // if it's a scriptblock, get the output
            if (cache is ScriptBlock)
            {
                cache = ((ScriptBlock)cache).Invoke();
            }

            // Try to convert it to blocks
            try
            {
                blocks = LanguagePrimitives.ConvertTo<Block[]>(cache);
                foreach (var block in blocks)
                {
                    block.BackgroundColor = block.BackgroundColor ?? DefaultBackgroundColor;
                    block.ForegroundColor = block.ForegroundColor ?? DefaultForegroundColor;
                }
            }
            catch
            {
                // If all else fails, make new ones using our default colors
                blocks = LanguagePrimitives.ConvertTo<string[]>(cache)
                                            .Select(o => new Block
                                            {
                                                Object = o,
                                                BackgroundColor = DefaultBackgroundColor,
                                                ForegroundColor = DefaultForegroundColor
                                            }).ToArray();
            }
            return blocks;
        }
    }

    public class Column
    {
        /// <summary>
        /// Gets the blocks
        /// </summary>
        public List<BlockFactory> Blocks { get; private set; }

        public Column()
        {
            Blocks = new List<BlockFactory>();
            Length = -1;
        }

        public Column(params BlockFactory[] blocks) : this()
        {
            Blocks.AddRange(blocks);
        }

        public Column(params Block[] blocks) : this()
        {
            // Convert BlockBase to BlockFactory
            Blocks.AddRange(blocks.Select(b => new BlockFactory(b)));
        }

        public Column(params object[] blocks) : this()
        {
            foreach (object block in blocks)
            {
                Blocks.AddRange(LanguagePrimitives.ConvertTo<BlockFactory[]>(block));
            }
        }

        public ConsoleColor? StartBackgroundColor { get; private set; }

        public ConsoleColor? EndBackgroundColor { get; private set; }

        public int Length { get; private set; }

        private Block[] ValidBlocks { get; set; }

        public Block[] PreCalculateValues()
        {
            // Calculate all the text and remove empty blocks
            ValidBlocks = Blocks.SelectMany(factory => factory.GetBlocks()).Where(e => e.Length >= 0).ToArray();
            Length = -1;
            if (ValidBlocks.Any())
            {
                Block block;
                StartBackgroundColor = (block = ValidBlocks.FirstOrDefault(b => b.BackgroundColor != null)) == null ? null : block.BackgroundColor;
                EndBackgroundColor = (block = ValidBlocks.LastOrDefault(b => b.BackgroundColor != null)) == null ? null : block.BackgroundColor;
                Length = ValidBlocks.Sum(b => b.Length) + (ValidBlocks.Length - 1);
            }
            return ValidBlocks;
        }

        public string ToString(string separator, string colorSeparator, bool rightJustified = false)
        {
            // Initialize variables ...
            var output = new StringBuilder();
            PreCalculateValues();

            for (int l = 0; l < ValidBlocks.Length; l++)
            {
                var block = ValidBlocks[l];
                output.Append(block);

                // Write a separator between blocks, unless the next one has no (non-escape) text
                if (l < ValidBlocks.Length - 1 && ValidBlocks[l + 1].Length > 0)
                {
                    // if the colors are the same, use the separator
                    if (block.BackgroundColor == ValidBlocks[l + 1].BackgroundColor)
                    {
                        output.Append(separator);
                    }
                    // if they're different, use the colorSeparator
                    else
                    {
                        if (rightJustified)
                        {
                            output.Append(AnsiHelper.WriteAnsi(ValidBlocks[l + 1].BackgroundColor, block.BackgroundColor, colorSeparator));
                        }
                        else
                        {
                            output.Append(AnsiHelper.WriteAnsi(block.BackgroundColor, ValidBlocks[l + 1].BackgroundColor, colorSeparator));
                        }
                    }
                }
            }
            // clear colors at the end of each column
            output.Append(AnsiHelper.Foreground["Default"]);
            output.Append(AnsiHelper.Background["Default"]);
            return output.ToString();
        }

        public override string ToString()
        {
            return ToString(Prompt.Separator, Prompt.ColorSeparator);
        }
    }


    public class Line
    {
        public List<Column> Columns { get; private set; }

        public Line()
        {
            Columns = new List<Column>();
        }

        public Line(params Column[] blocks) : this()
        {
            Columns.AddRange(blocks);
        }

        public Line(object[] columns) : this()
        {
            Column[] cols;
            if (LanguagePrimitives.TryConvertTo(columns, out cols))
            {
                Columns.AddRange(cols);
                return;
            }

            // Console.WriteLine("Fallback to single column");
            Column column;
            if (LanguagePrimitives.TryConvertTo(columns, out column))
            {
                Columns.Add(column);
                return;
            }

            // Console.WriteLine("Fallback to casting one at a time");
            foreach (object col in columns)
            {
                if (col == null)
                {
                    Columns.Add(new Column());
                    continue;
                }

                if (LanguagePrimitives.TryConvertTo(columns, out column))
                {
                    Columns.Add(column);
                    continue;
                }

                // Console.WriteLine("Fallback to block factories");
                // This should let us skip explicitly having columns
                BlockFactory[] factories;
                if (LanguagePrimitives.TryConvertTo(columns, out factories))
                {
                    Columns.Add(new Column(factories));
                    continue;
                }

                // Console.WriteLine("Fallback to a single block factory");
                BlockFactory factory;
                if (LanguagePrimitives.TryConvertTo(columns, out factory))
                {
                    Columns.Add(new Column(factory));
                    continue;
                }
            }
        }

        public List<Column> PreCalculateValues()
        {
            // Calculate all the text and remove empty blocks
            foreach (var column in Columns)
            {
                if (column != null)
                {
                    column.PreCalculateValues();
                }
            }

            return Columns;
        }

        public override string ToString()
        {
            return ToString(Console.BufferWidth);
        }

        public string ToString(int width)
        {
            var columns = PreCalculateValues();

            var output = new StringBuilder();
            // Output each block with appropriate separators and caps
            for (int l = 0; l < columns.Count;)
            {
                var column = columns[l];
                // Use null columns as spacers
                if (column != null && column.Length > 0)
                {
                    string text = column.ToString(Prompt.Separator, Prompt.ColorSeparator);
                    output.Append(text);
                    output.Append(AnsiHelper.WriteAnsi(column.EndBackgroundColor, null, Prompt.ColorSeparator));
                }

                // Force the prompt location to the end of the first column
                output.Append(AnsiHelper.EscapeCodes.PromptLocation);

                // CURRENTLY we only support two columns, so ...
                // if there are more columns, the next one is right-aligned
                if (columns.Count > ++l)
                {
                    column = columns[l];
                    // Use null columns as spacers
                    if (column != null && column.Length > 0)
                    {
                        // Move to the start location for the next column
                        output.Append(AnsiHelper.EscapeCodes.Esc + (width - column.Length) + "G");

                        output.Append(AnsiHelper.WriteAnsi(column.StartBackgroundColor, null, Prompt.ReverseColorSeparator));
                        output.Append(column.ToString(Prompt.ReverseSeparator, Prompt.ReverseColorSeparator, true));
                    }
                }

                if (columns.Count > ++l)
                {
                    // Because we only support two columns, if there are still more columns, they must go on the next line
                    output.Append("\n");
                }
            }

            return output.ToString();
        }
    }

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

            Line[] lns;
            if (LanguagePrimitives.TryConvertTo(lines, out lns))
            {
                Lines.AddRange(lns);
                return;
            }

            Line ln;
            if (LanguagePrimitives.TryConvertTo(lines, out ln))
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
                output.Append(AnsiHelper.EscapeCodes.Esc + Math.Abs(PrefixLines) + "A");
            }

            output.Append(string.Join("\n", Lines.Select(l => l.ToString(width))));
            output.Append(AnsiHelper.Foreground["Default"]);
            output.Append(AnsiHelper.Background["Default"]);
            output.Append(AnsiHelper.EscapeCodes.Recall);

            return output.ToString();
        }

    }
}
