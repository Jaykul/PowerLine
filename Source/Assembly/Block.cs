using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using PoshCode.Pansies;

namespace PoshCode.PowerLine
{
    public class Block : PoshCode.Pansies.Text
    {
        public object Cap { get; set; } = string.Empty;

        private RgbColor elevatedForegroundColor;
        public RgbColor ElevatedForegroundColor
        {
            get
            {
                return elevatedForegroundColor; // ?? foregroundColor;
            }
            set
            {
                elevatedForegroundColor = value;
            }
        }

        private RgbColor elevatedBackgroundColor;
        public RgbColor ElevatedBackgroundColor
        {
            get
            {
                return elevatedBackgroundColor;// ?? backgroundColor;
            }
            set
            {
                elevatedBackgroundColor = value;
            }
        }

        private RgbColor errorForegroundColor;
        public RgbColor ErrorForegroundColor
        {
            get
            {
                return errorForegroundColor; // ?? foregroundColor;
            }
            set
            {
                errorForegroundColor = value;
            }
        }

        private RgbColor errorBackgroundColor;
        public RgbColor ErrorBackgroundColor
        {
            get
            {
                return errorBackgroundColor;// ?? backgroundColor;
            }
            set
            {
                errorBackgroundColor = value;
            }
        }

        private RgbColor foregroundColor;
        public new RgbColor ForegroundColor {
            get {
                if (State.Elevated && null != ElevatedForegroundColor)
                {
                    return ElevatedForegroundColor;
                }
                else if(!State.LastSuccess && null != ErrorForegroundColor)
                {
                    return ErrorForegroundColor;
                }
                else
                {
                    return foregroundColor;
                }
            }
            set {
                foregroundColor = value;
            }
        }

        private RgbColor backgroundColor;
        public new RgbColor BackgroundColor {
            get {
                if (State.Elevated && null != ElevatedBackgroundColor)
                {
                    return ElevatedBackgroundColor;
                }
                else if (!State.LastSuccess && null != ErrorBackgroundColor)
                {
                    return ErrorBackgroundColor;
                }
                else
                {
                    return backgroundColor;
                }
            }
            set {
                backgroundColor = value;
            }
        }
        /// <summary>
        /// This constructor is here so we can allow partial matches to the property names.
        /// </summary>
        /// <param name="values"></param>
        public Block(IDictionary values) : this()
        {
            foreach (string key in values.Keys)
            {
                var pattern = "^" + Regex.Escape(key);
                if ("Abg".Equals(key, StringComparison.OrdinalIgnoreCase) || Regex.IsMatch("ElevatedBackgroundColor", pattern, RegexOptions.IgnoreCase) || Regex.IsMatch("AdminBackgroundColor", pattern, RegexOptions.IgnoreCase))
                {
                    ElevatedBackgroundColor = RgbColor.ConvertFrom(values[key]);
                }
                else if ("Afg".Equals(key, StringComparison.OrdinalIgnoreCase) || Regex.IsMatch("ElevatedForegroundColor", pattern, RegexOptions.IgnoreCase) || Regex.IsMatch("AdminForegroundColor", pattern, RegexOptions.IgnoreCase))
                {
                    ElevatedForegroundColor = RgbColor.ConvertFrom(values[key]);
                }
                else if ("Ebg".Equals(key, StringComparison.OrdinalIgnoreCase) || Regex.IsMatch("ErrorBackgroundColor", pattern, RegexOptions.IgnoreCase))
                {
                    ErrorBackgroundColor = RgbColor.ConvertFrom(values[key]);
                }
                else if ("Efg".Equals(key, StringComparison.OrdinalIgnoreCase) || Regex.IsMatch("ErrorForegroundColor", pattern, RegexOptions.IgnoreCase))
                {
                    ErrorForegroundColor = RgbColor.ConvertFrom(values[key]);
                }
                else if ("bg".Equals(key, StringComparison.OrdinalIgnoreCase) || Regex.IsMatch("BackgroundColor", pattern, RegexOptions.IgnoreCase))
                {
                    BackgroundColor = RgbColor.ConvertFrom(values[key]);
                }
                else if ("fg".Equals(key, StringComparison.OrdinalIgnoreCase) || Regex.IsMatch("ForegroundColor", pattern, RegexOptions.IgnoreCase))
                {
                    ForegroundColor = RgbColor.ConvertFrom(values[key]);
                }
                else if (Regex.IsMatch("text", pattern, RegexOptions.IgnoreCase) || Regex.IsMatch("Content", pattern, RegexOptions.IgnoreCase) || Regex.IsMatch("Object", pattern, RegexOptions.IgnoreCase))
                {
                    Object = values[key];
                    if (Object.ToString() == "\t") {
                        Object = Space.RightAlign;
                    } else if (Object.ToString() == "\n") {
                        Object = Space.NewLine;
                    } else if (Object.ToString() == " ") {
                        Object = Space.Spacer;
                    }

                    if (Object is Space) {
                        Cap = new Separator("");
                    }
                }
                else if (Regex.IsMatch("clear", pattern, RegexOptions.IgnoreCase) )
                {
                    Clear = (bool)values[key];
                }
                else if (Regex.IsMatch("entities", pattern, RegexOptions.IgnoreCase) )
                {
                    Entities = (bool)values[key];
                }
                else if (Regex.IsMatch("separator", pattern, RegexOptions.IgnoreCase) )
                {
                    if (values[key] is Separator)
                    {
                        base.Separator = (Separator)values[key];
                    }
                    else if (values[key] is Array && ((Array)values[key]).Length > 1)
                    {
                        var kv = (Array)values[key];
                        base.Separator = new Separator(kv.GetValue(0).ToString(), kv.GetValue(1).ToString());
                    }
                    else
                    {
                        base.Separator = new Separator(values[key].ToString());
                    }
                }
                else if (Regex.IsMatch("cap", pattern, RegexOptions.IgnoreCase))
                {
                    if (values[key] is Separator)
                    {
                        Cap = (Separator)values[key];
                    }
                    else if (values[key] is Array && ((Array)values[key]).Length > 1)
                    {
                        var kv = (Array)values[key];
                        Cap = new Separator(kv.GetValue(0).ToString(), kv.GetValue(1).ToString());
                    }
                    else
                    {
                        Cap = new Separator(values[key].ToString());
                    }
                }
                else if (Regex.IsMatch("persist", pattern, RegexOptions.IgnoreCase) )
                {
                    PersistentColor = (bool)values[key];
                }
                else
                {
                    throw new ArgumentException("Unknown key '" + key + "' in " + values.GetType().Name + ". Allowed values are BackgroundColor (or bg), ForegroundColor (or fg), and Object (also called Content or Text), or Separator, Clear, and Entities");
                }
            }
        }

        // Make sure we support the default ctor
        public Block() : this("") { }

        // Make sure we can output plain text
        public Block(object @object) {
            var cap = new Separator();
            var sep = new Separator();

            var chars = PoshCode.Pansies.Entities.ExtendedCharacters;
            if (chars.ContainsKey("ColorSeparator"))
            {
                cap.Left = chars["ColorSeparator"];
            }
            if (chars.ContainsKey("ReverseColorSeparator"))
            {
                cap.Right = chars["ReverseColorSeparator"];
            }
            if (chars.ContainsKey("Separator"))
            {
                sep.Left = chars["Separator"];
            }
            if (chars.ContainsKey("ReverseSeparator"))
            {
                sep.Right = chars["ReverseSeparator"];
            }

            Cap = cap;
            this.Separator = sep;
            this.Object = @object;
        }

        public override string ToString()
        {
            return GetString(ForegroundColor, BackgroundColor, Object, Separator?.ToString(), Cap?.ToString(),  Clear, Entities, PersistentColor);
        }

        public string ToLine(RgbColor otherBackground)
        {
            return GetString(ForegroundColor, BackgroundColor, Object, Separator?.ToString(), Cap?.ToString(), Clear, Entities, PersistentColor, otherBackground);
        }

        public static string GetString(RgbColor foreground, RgbColor background, object @object, string separator = " ", string cap = null, bool clear = false, bool entities = true, bool persistentColor = true, RgbColor otherBackground = null)
        {
            var output = new StringBuilder();

            if (cap != null && State.Alignment == Alignment.Right)
            {
                if (null != otherBackground)
                {
                    output.Append(otherBackground.ToVtEscapeSequence(true));
                }
                if (null != background)
                {
                    output.Append(background.ToVtEscapeSequence(false));
                }
                output.Append(cap);
                // clear foreground
                output.Append("\u001B[39m");
            }

            if (null != foreground)
            {
                // There was a bug in Conhost where an advanced 48;2 RGB code followed by a console code wouldn't render the RGB value
                // So we try to put the ConsoleColor first, if it's there ...
                if (foreground.Mode == ColorMode.ConsoleColor)
                {
                    output.Append(foreground.ToVtEscapeSequence(false));
                    if (null != background)
                    {
                        output.Append(background.ToVtEscapeSequence(true));
                    }
                }
                else
                {
                    if (null != background)
                    {
                        output.Append(background.ToVtEscapeSequence(true));
                    }
                    output.Append(foreground.ToVtEscapeSequence(false));
                }
            }
            else if (null != background)
            {
                output.Append(background.ToVtEscapeSequence(true));
            }

            // set the color back after each item if Object is an array
            if (persistentColor) {
                separator = output.ToString() + separator;
            }


            if (null != @object)
            {
                //var scriptBlock = @object as ScriptBlock;
                //var text = (string)LanguagePrimitives.ConvertTo(scriptBlock != null ? scriptBlock.Invoke() : @object, typeof(string));
                var text = ConvertToString(@object, separator);

                if (!string.IsNullOrEmpty(text))
                {
                    output.Append(text);
                }
            }

            if (cap != null && State.Alignment == Alignment.Left)
            {
                // clear background
                output.Append("\u001B[49m");
                if (null != otherBackground)
                {
                    output.Append(otherBackground.ToVtEscapeSequence(true));
                }
                if (null != background)
                {
                    output.Append(background.ToVtEscapeSequence(false));
                }
                output.Append(cap);
            }

            if (clear)
            {
                if (null != background)
                {
                    // clear background
                    output.Append("\u001B[49m");
                }
                if (null != foreground)
                {
                    // clear foreground
                    output.Append("\u001B[39m");
                }
            }

            output.Append("\u001B[0m");

            if (entities)
            {
                return PoshCode.Pansies.Entities.Decode(output.ToString());
            }
            else
            {
                return output.ToString();
            }
        }

        public bool Equals(Block other)
        {
            return other != null && (Object == other.Object && ForegroundColor == other.ForegroundColor && BackgroundColor == other.BackgroundColor) && Separator == other.Separator && Cap == other.Cap;
        }
    }

}
