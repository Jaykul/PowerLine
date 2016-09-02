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
            string colorCode = color == null ? "Clear" : color.ToString();

            return forBackground ? Background[colorCode] : Foreground[colorCode];

        }
        public static Dictionary<string, string> Foreground = new Dictionary<string, string>
            {
                {"Clear",       "\u001B[39m"},
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
                {"Clear",       "\u001B[49m"},
                {"Black",       "\u001B[40m"}, {"DarkGray", "\u001B[100m"},
                {"DarkRed",     "\u001B[41m"}, {"Red",      "\u001B[101m"},
                {"DarkGreen",   "\u001B[42m"}, {"Green",    "\u001B[102m"},
                {"DarkYellow",  "\u001B[43m"}, {"Yellow",   "\u001B[103m"},
                {"DarkBlue",    "\u001B[44m"}, {"Blue",     "\u001B[104m"},
                {"DarkMagenta", "\u001B[45m"}, {"Magenta",  "\u001B[105m"},
                {"DarkCyan",    "\u001B[46m"}, {"Cyan",     "\u001B[106m"},
                {"Gray",        "\u001B[47m"}, {"White",    "\u001B[107m"},
            };


        public static string WriteAnsi(ConsoleColor? foreground, ConsoleColor? background, string value, bool clear = false)
        {
            var output = new StringBuilder();

            output.Append(background.GetCode(true));
            output.Append(foreground.GetCode());

            output.Append(value);
            if (clear)
            {
                output.Append(AnsiHelper.Background["Clear"]);
                output.Append(AnsiHelper.Foreground["Clear"]);
            }
            return output.ToString();
        }

        public static string GetString(object @object)
        {
            return (string)LanguagePrimitives.ConvertTo(@object is ScriptBlock ? ((ScriptBlock)@object).Invoke() : @object, typeof(string));
        }

        public struct EscapeCodes
        {
            public static readonly string ESC = "\u001B[";
            public static readonly string Clear = "\u001B[0m";
            public static readonly string Store = "\u001B[s";
            public static readonly string Recall = "\u001B[u";
        };
    }

    public class Block
    {
        public static string LeftCap = "\ue0b0"; // right-pointing arrow
        public static string RightCap = "\ue0b2"; // left-pointing arrow
        public static string LeftSep = "\ue0b1"; // left open >
        public static string RightSep = "\ue0b3"; // right open <
        public static string Branch = "\ue0a0"; // Branch symbol
        public static string LOCK = "\ue0a2"; // Padlock
        public static string GEAR = "\u26ef"; // The settings icon, I use it for debug
        public static string POWER = "\u26a1"; // The Power lightning-bolt icon

        public ConsoleColor? BackgroundColor { get; set; }
        public ConsoleColor? ForegroundColor { get; set; }

        public object Object { get; set; }

        public bool Clear { get; set; }

        public Block() { }

        // copy constructor
        public Block(Block block)
        {
            BackgroundColor = block.BackgroundColor;
            ForegroundColor = block.ForegroundColor;
            Object = block.Object;
        }

        public Block(IDictionary values)
        {
            foreach (string key in values.Keys)
            {
                var pattern = "^" + Regex.Escape(key);
                if ("bg".Equals(key, System.StringComparison.InvariantCultureIgnoreCase) || Regex.IsMatch("BackgroundColor", pattern, RegexOptions.IgnoreCase))
                {
                    BackgroundColor = (ConsoleColor)Enum.Parse(typeof(ConsoleColor), values[key].ToString(), true);
                }
                else if ("fg".Equals(key, System.StringComparison.InvariantCultureIgnoreCase) || Regex.IsMatch("ForegroundColor", pattern, RegexOptions.IgnoreCase))
                {
                    ForegroundColor = (ConsoleColor)Enum.Parse(typeof(ConsoleColor), values[key].ToString(), true);
                }
                else if (Regex.IsMatch("text", pattern, RegexOptions.IgnoreCase) || Regex.IsMatch("Content", pattern, RegexOptions.IgnoreCase) || Regex.IsMatch("Object", pattern, RegexOptions.IgnoreCase))
                {
                    Object = values[key];
                }
                else if (Regex.IsMatch("Clear", pattern, RegexOptions.IgnoreCase))
                {
                    Clear = (bool)values[key];
                }
                else
                {
                    throw new ArgumentException("Unknown key '" + key + "' in hashtable. Allowed values are BackgroundColor, ForegroundColor, Content, and Clear");
                }
            }
        }

        /// <summary>
        /// Get the Object rendered to text.
        /// With special handling for ScriptBlocks and Blocks, and ScriptBlocks which output Blocks...
        /// </summary>
        /// <returns></returns>
        public string GetObjectText()
        {
            object value = Object;

            if (Object is ScriptBlock)
            {
                value = ((ScriptBlock)Object).Invoke();
            }

            if (Object is IEnumerable<ScriptBlock>)
            {
                value = ((IEnumerable<ScriptBlock>)Object)
                            .SelectMany(block => block.Invoke()
                                .Select(pso => pso.BaseObject))
                            .Select(o => o is Block ? ((Block)o).GetObjectText() : o);
            }

            if (value is Block)
            {
                value = ((Block)value).GetObjectText();
            }

            if (value is IEnumerable<Block>)
            {
                value = ((IEnumerable<Block>)value).Select(block => block.GetObjectText());
            }

            if (value is IEnumerable<object>)
            {
                value = ((IEnumerable<object>)value).Select(o => o is Block ? ((Block)o).GetObjectText() : o);
            }

            return (string)LanguagePrimitives.ConvertTo(value, typeof(string));
        }

        public override string ToString()
        {
            object value = Object;
            string text = null;

            if (Object is ScriptBlock)
            {
                value = ((ScriptBlock)Object).Invoke();
            }
            if (value is Block)
            {
                return value.ToString();
            }

            if (Object is IEnumerable<ScriptBlock>)
            {
                text = AnsiHelper.GetString(((IEnumerable<ScriptBlock>)Object)
                            .SelectMany(block => block.Invoke()
                                .Select(pso => pso.BaseObject))
                            .Select(o => o is Block ? ((Block)o).ToString() : AnsiHelper.GetString(o)));
            }

            if (value is IEnumerable<Block>)
            {
                text = AnsiHelper.GetString(((IEnumerable<Block>)value).Select(block => block.ToString()));
            }

            if (value is IEnumerable<object>)
            {
                text = AnsiHelper.GetString(((IEnumerable<object>)value).Select(o => o is Block ? ((Block)o).ToString() : AnsiHelper.GetString(o)));
            }

            return AnsiHelper.WriteAnsi(ForegroundColor, BackgroundColor, text ?? GetObjectText(), Clear);
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

            // Console.WriteLine("Is " + GetType().FullName + " '" + Content + "' == " + obj.GetType().FullName + " '" + other.Content + "'");
            return Object == other.Object && ForegroundColor == other.ForegroundColor && BackgroundColor == other.BackgroundColor;
        }

        // override object.GetHashCode
        public override int GetHashCode()
        {
            return Object.GetHashCode() + BackgroundColor.GetHashCode() + ForegroundColor.GetHashCode();
        }
    }

    public class BlockCache : Block
    {
        private string _text;
        new public string Object
        {
            get
            {
                return _text ?? GetObjectText();
            }
            set
            {
                _text = value;
                base.Object = value;
                Length = _text.Length;
            }
        }

        public int Length { get; private set; }

        public static BlockCache Column = new BlockCache() { Object = "\t" };
        public static BlockCache Prompt = new BlockCache() { Object = AnsiHelper.EscapeCodes.Store };

        public BlockCache() { }

        public BlockCache(Block block)
        {
            BackgroundColor = block.BackgroundColor;
            ForegroundColor = block.ForegroundColor;
            Object = block.GetObjectText();
            Length = Object.Length;
        }

        public override string ToString()
        {
            return AnsiHelper.WriteAnsi(ForegroundColor, BackgroundColor, Object, Clear);
        }
    }

    public static class Cacher
    {
        public static BlockCache Cache(this Block block)
        {
            return block is BlockCache ? (BlockCache)block : new BlockCache(block);
        }
    }

    public class Line : List<Block>
    {
        public Line() { }

        public Line(params Block[] blocks) : base(blocks) { }

        public Line(object[] blocks)
        {
            AddRange(blocks.Select(b => b is Hashtable ? new Block((Hashtable)b) : (Block)b));
        }

        public override string ToString()
        {
            // Initialize variables ...
            var width = Console.BufferWidth;
            var leftLength = 0;
            var rightLength = 0;

            // Precalculate all the text and remove empty blocks
            var ValidBlocks = this.Select(e => e.Cache()).Where(e => e.Length > 0).ToArray();

            var output = new StringBuilder();
            // Output each block with appropriate separators and caps
            for (int l = 0; l < ValidBlocks.Length; l++)
            {
                var block = ValidBlocks[l];

                // Console.WriteLine("Is '" + block + "' a Column? " + BlockCache.Column.Equals(block) + " or a Prompt? " + BlockCache.Prompt.Equals(block));
                if (BlockCache.Column.Equals(block))
                {
                    // the length of the second column
                    rightLength = ValidBlocks.Skip(l + 1).Sum(e => e.Length + 1) - 1;

                    var space = width - rightLength;

                    // Output a cap on the left if there isn't one already
                    if (l > 0 && !BlockCache.Prompt.Equals(ValidBlocks[l - 1]))
                    {
                        // Use the Background of the previous block as the foreground
                        output.Append(AnsiHelper.WriteAnsi(ValidBlocks[l - 1].BackgroundColor, null, Block.LeftCap, true));
                    }

                    output.Append(AnsiHelper.EscapeCodes.ESC + space + "G");

                    if (l < ValidBlocks.Length)
                    {
                        // the right cap uses the background of the next block as it's foreground
                        output.Append(AnsiHelper.WriteAnsi(ValidBlocks[l + 1].BackgroundColor, null, Block.RightCap));
                    }
                }
                else if (BlockCache.Prompt.Equals(block))
                {
                    output.Append(block.ToString());
                }
                else
                {
                    if (leftLength == 0 && rightLength == 0)
                    {
                        // On a new line, recalculate the length of the "left-aligned" line
                        leftLength = ValidBlocks.TakeWhile(e => !BlockCache.Column.Equals(e)).Sum(e => e.Length + 1);
                    }

                    output.Append(block.ToString());

                    // Write a separator between blocks
                    if (l + 1 < ValidBlocks.Length && !BlockCache.Column.Equals(ValidBlocks[l + 1]))
                    {
                        // if the next block is the sambe background color, use a >
                        if (block.BackgroundColor == ValidBlocks[l + 1].BackgroundColor)
                        {
                            output.Append(rightLength > 0 ? Block.RightSep : Block.LeftSep);
                        }
                        else
                        {
                            if (rightLength > 0)
                            {
                                output.Append(AnsiHelper.WriteAnsi(ValidBlocks[l + 1].BackgroundColor, block.BackgroundColor, Block.RightCap));
                            }
                            else
                            {
                                output.Append(AnsiHelper.WriteAnsi(block.BackgroundColor, ValidBlocks[l + 1].BackgroundColor, Block.LeftCap));
                            }
                        }
                    }
                }
            }

            // Output a cap on the left if we didn't already
            if (rightLength == 0 && leftLength > 0)
            {
                output.Append(AnsiHelper.WriteAnsi(ValidBlocks.Last().BackgroundColor, null, Block.LeftCap, true));
            }
            // clear the end of each line in case it's not part of a prompt.
            output.Append(AnsiHelper.Foreground["Clear"]);
            output.Append(AnsiHelper.Background["Clear"]);
            return output.ToString();
        }
    }

    public class Prompt : List<Line>
    {
        public bool SetTitle { get; set; }
        public bool SetCurrentDirectory { get; set; }
        public int PrefixLines { get; set; }

        public Prompt() { }

        public Prompt(int prefixLines, params Line[] lines) : base(lines)
        {
            PrefixLines = prefixLines;
        }

        public Prompt(params Line[] lines) : base(lines) { }

        public Prompt(object[] lines)
        {
            if (lines.First() is int)
            {
                PrefixLines = (int)lines.First();
                lines = lines.Skip(1).ToArray();
            }

            AddRange(lines.Select(b => b is Block[] ?
                                        new Line((Block[])b) :
                                            b is object[] ?
                                                new Line((object[])b) :
                                                (Line)b));
        }

        public override string ToString()
        {
            var output = new StringBuilder();

            // Move up to previous line(s)
            if (PrefixLines != 0)
            {
                output.Append(AnsiHelper.EscapeCodes.ESC + Math.Abs(PrefixLines) + "A");
            }
            output.Append(string.Join("\n", this));

            if (this.Any(line => line.Any(block => BlockCache.Prompt.Equals(block))))
            {
                output.Append(AnsiHelper.EscapeCodes.Recall);
            }
            output.Append(AnsiHelper.Foreground["Clear"]); // Default
            output.Append(AnsiHelper.Background["Clear"]); // Default
            return output.ToString();
        }
    }
}
