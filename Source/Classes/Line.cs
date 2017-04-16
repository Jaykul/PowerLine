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
            if (LanguagePrimitives.TryConvertTo(columns, out Column[] cols))
            {
                Columns.AddRange(cols);
                return;
            }

            // Console.WriteLine("Fallback to single column");
            if (LanguagePrimitives.TryConvertTo(columns, out Column column))
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
                if (LanguagePrimitives.TryConvertTo(columns, out TextFactory[] factories))
                {
                    Columns.Add(new Column(factories));
                    continue;
                }

                // Console.WriteLine("Fallback to a single block factory");
                if (LanguagePrimitives.TryConvertTo(columns, out TextFactory factory))
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
                    output.Append(Text.GetString(column.EndBackgroundColor, null, Prompt.ColorSeparator));
                }

                // Force the prompt location to the end of the first column
                output.Append(Entities.EscapeSequences["Store"]);

                // CURRENTLY we only support two columns, so ...
                // if there are more columns, the next one is right-aligned
                if (columns.Count > ++l)
                {
                    column = columns[l];
                    // Use null columns as spacers
                    if (column != null && column.Length > 0)
                    {
                        // Move to the start location for the next column
                        output.Append(Entities.EscapeSequences["Esc"] + (width - column.Length) + "G");

                        output.Append(Text.GetString(column.StartBackgroundColor, null, Prompt.ReverseColorSeparator));
                        output.Append(column.ToString(Prompt.ReverseSeparator, Prompt.ReverseColorSeparator, true));
                    }
                }

                if (columns.Count > ++l)
                {
                    // Because we only support two columns, if there are still more columns, they must go on the next line
                    output.Append("\n");
                }
            }
            // clear
            output.Append(Entities.EscapeSequences["Clear"]);

            return output.ToString();
        }
    }
}