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
}