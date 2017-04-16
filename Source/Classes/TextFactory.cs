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
    /// <summary>
    /// The Text factory is a Text which supports scriptblocks that output Text ...
    /// </summary>
    public class TextFactory
    {
        /// <summary>
        /// Gets or Sets the background color for the block
        /// </summary>
        [Alias("BackgroundColor", "Bg")]
        public Color DefaultBackgroundColor { get; set; }

        /// <summary>
        /// Gets or Sets the foreground color for the block
        /// </summary>
        [Alias("ForegroundColor", "Fg")]
        public Color DefaultForegroundColor { get; set; }

        /// <summary>
        /// Gets or Sets the object to be rendered.
        /// Can be any object, but with particular support for nested lists of objects, Text, or ScriptBlocks which output them.
        /// </summary>
        [Alias("Text", "Content")]
        public object Object { get; set; }

        /// <summary>
        /// This constructor is here so we can allow partial matches to the property names.
        /// </summary>
        /// <param name="values"></param>
        public TextFactory(IDictionary values)
        {
            foreach (string key in values.Keys)
            {
                var pattern = "^" + Regex.Escape(key);
                if ("bg".Equals(key, StringComparison.OrdinalIgnoreCase) || Regex.IsMatch("BackgroundColor", pattern, RegexOptions.IgnoreCase))
                {
                    DefaultBackgroundColor = Color.ConvertFrom(values[key]);
                }
                else if ("fg".Equals(key, StringComparison.OrdinalIgnoreCase) || Regex.IsMatch("ForegroundColor", pattern, RegexOptions.IgnoreCase))
                {
                    DefaultForegroundColor = Color.ConvertFrom(values[key]);
                }
                else if (Regex.IsMatch("text", pattern, RegexOptions.IgnoreCase) || Regex.IsMatch("Content", pattern, RegexOptions.IgnoreCase) || Regex.IsMatch("Object", pattern, RegexOptions.IgnoreCase))
                {
                    Object = values[key];
                }
                else
                {
                    throw new ArgumentException("Unknown key '" + key + "' in " + values.GetType().Name + ". Allowed values are BackgroundColor (or bg), ForegroundColor (or fg), and Object (also called Content or Text)");
                }
            }
        }

        public TextFactory(Text text)
        {
            Object = text;
        }

        public TextFactory(params Text[] texts)
        {
            Object = texts;
        }

        public Text[] GetText()
        {
            // There are four allowed values:
            // 1. A scriptblock, which outputs one of the other possibilities
            // 2. One or more Text objects
            // 3. Things we'll convert to text
            IEnumerable<object> cache;
            var output = new List<Text>();

            // if it's a scriptblock, get the output
            if (Object is ScriptBlock)
            {
                cache = ((ScriptBlock)Object).Invoke().Cast<object>();
            }
            else if(Object is string)
            {
                cache = new[] { Object };
            }
            else if(Object is IEnumerable)
            {
                cache = ((IEnumerable)Object).Cast<object>();
            }
            else
            {
                cache = new[] { Object };
            }

            // Try to convert it to blocks
            foreach (var input in cache) {
                try
                {
                    var textBlocks = LanguagePrimitives.ConvertTo<Text[]>(input);
                    foreach (var block in textBlocks)
                    {
                        block.BackgroundColor = block.BackgroundColor ?? DefaultBackgroundColor;
                        block.ForegroundColor = block.ForegroundColor ?? DefaultForegroundColor;
                        output.Add(block);
                    }
                }
                catch
                {
                    try
                    {
                        var textBlock = LanguagePrimitives.ConvertTo<Text>(input);
                        textBlock.BackgroundColor = textBlock.BackgroundColor ?? DefaultBackgroundColor;
                        textBlock.ForegroundColor = textBlock.ForegroundColor ?? DefaultForegroundColor;
                        output.Add(textBlock);
                    }
                    catch
                    {
                        try
                        {
                            // If all else fails, make new ones using our default colors
                            var textStrings = LanguagePrimitives.ConvertTo<string[]>(input);
                            if (textStrings != null && textStrings.Length > 0)
                            {
                                var text = textStrings.Select(o => new Text
                                {
                                    Object = o,
                                    BackgroundColor = DefaultBackgroundColor,
                                    ForegroundColor = DefaultForegroundColor
                                }).ToArray();
                                output.AddRange(text);
                            }
                        }
                        catch
                        {
                            output.Add(new Text
                            {
                                Object = input.ToString(),
                                BackgroundColor = DefaultBackgroundColor,
                                ForegroundColor = DefaultForegroundColor
                            });
                        }
                    }
                }
            }
            return output.ToArray();
        }
    }
}