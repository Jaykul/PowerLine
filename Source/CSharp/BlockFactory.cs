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
}