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
    public class Column
    {
        /// <summary>
        /// Gets the blocks
        /// </summary>
        public List<TextFactory> Blocks { get; private set; }

        public Column()
        {
            Blocks = new List<TextFactory>();
            Length = -1;
        }

        public Column(params TextFactory[] blocks) : this()
        {
            Blocks.AddRange(blocks);
        }

        public Column(params Text[] blocks) : this()
        {
            // Convert BlockBase to TextFactory
            Blocks.AddRange(blocks.Select(b => new TextFactory(b)));
        }

        public Column(params object[] blocks) : this()
        {
            foreach (object block in blocks)
            {
                Blocks.AddRange(LanguagePrimitives.ConvertTo<TextFactory[]>(block));
            }
        }

        public RgbColor StartBackgroundColor { get; private set; }

        public RgbColor EndBackgroundColor { get; private set; }

        public int Length { get; private set; }

        private Text[] ValidBlocks { get; set; }

        public Text[] PreCalculateValues()
        {
            // Calculate all the text and remove empty blocks
            ValidBlocks = Blocks.SelectMany(factory => factory.GetText()).Where(e => e.Length >= 0).ToArray();
            Length = -1;
            if (ValidBlocks.Any())
            {
                Text block;
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
                            output.Append(Text.GetString(ValidBlocks[l + 1].BackgroundColor, block.BackgroundColor, colorSeparator));
                        }
                        else
                        {
                            output.Append(Text.GetString(block.BackgroundColor, ValidBlocks[l + 1].BackgroundColor, colorSeparator));
                        }
                    }
                }
            }
            // clear background colors at the end of each column
            output.Append("\u001B[49m");
            // clear foreground colors at the end of each column
            output.Append("\u001B[39m");
            return output.ToString();
        }

        public override string ToString()
        {
            return ToString(Prompt.Separator, Prompt.ColorSeparator);
        }
    }
}