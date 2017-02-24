using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Text;
using System.Text.RegularExpressions;

namespace PowerLine
{
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
}