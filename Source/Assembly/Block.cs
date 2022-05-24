using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Text;
using System.Text.RegularExpressions;
using PoshCode.Pansies;

namespace PoshCode.PowerLine
{
    public class Block : PoshCode.Pansies.Text, IPsMetadataSerializable
    {
        public Cap Cap { get; set; }
        public new Cap Separator
        {
            get
            {
                return (Cap)base.Separator;
            }
            set
            {
                base.Separator = value;
            }
        }

        public RgbColor ElevatedForegroundColor { get; set; }
        public RgbColor ElevatedBackgroundColor { get; set; }
        public RgbColor ErrorForegroundColor { get; set; }
        public RgbColor ErrorBackgroundColor { get; set; }

        private RgbColor foregroundColor;
        public new RgbColor ForegroundColor
        {
            get
            {
                if (State.Elevated && null != ElevatedForegroundColor)
                {
                    return ElevatedForegroundColor;
                }
                else if (!State.LastSuccess && null != ErrorForegroundColor)
                {
                    return ErrorForegroundColor;
                }
                else
                {
                    return foregroundColor;
                }
            }
            set
            {
                foregroundColor = value;
            }
        }

        private RgbColor backgroundColor;
        public new RgbColor BackgroundColor
        {
            get
            {
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
            set
            {
                backgroundColor = value;
            }
        }

        /// <summary>
        /// Gets or sets the object.
        /// </summary>
        /// <value>A string</value>
        public new object Object
        {
            get
            {
                return base.Object;
            }
            set
            {
                var spaceTest = value.ToString().Trim();
                if (spaceTest.Equals("\"`t\"") || spaceTest.Equals("`t"))
                {
                    base.Object = Space.RightAlign;
                }
                else if (spaceTest.Equals("\"`n\"") || spaceTest.Equals("`n"))
                {
                    base.Object = Space.NewLine;
                }
                else if (spaceTest.Equals("\" \"") || spaceTest.Equals(" "))
                {
                    base.Object = Space.Spacer;
                }
                else
                {
                    base.Object = value;
                }
            }
        }

        /// <summary>
        /// This constructor is here so we can allow partial matches to the property names.
        /// </summary>
        /// <param name="values"></param>
        public Block(IDictionary values) : this()
        {
            FromDictionary(values);
        }
        private void FromDictionary(IDictionary values)
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
                else if (Regex.IsMatch("InputObject", pattern, RegexOptions.IgnoreCase) || Regex.IsMatch("text", pattern, RegexOptions.IgnoreCase) || Regex.IsMatch("Content", pattern, RegexOptions.IgnoreCase) || Regex.IsMatch("Object", pattern, RegexOptions.IgnoreCase))
                {
                    Object = values[key];
                }
                else if (Regex.IsMatch("clear", pattern, RegexOptions.IgnoreCase))
                {
                    Clear = LanguagePrimitives.ConvertTo<bool>(values[key]);
                }
                else if (Regex.IsMatch("entities", pattern, RegexOptions.IgnoreCase))
                {
                    Entities = LanguagePrimitives.ConvertTo<bool>(values[key]);
                }
                else if (Regex.IsMatch("separator", pattern, RegexOptions.IgnoreCase))
                {
                    if (values[key] is Cap)
                    {
                        Separator = (Cap)values[key];
                    }
                    else if (values[key] is Array array && array.Length > 1)
                    {
                        Separator = new Cap(array.GetValue(0).ToString(), array.GetValue(1).ToString());
                    }
                    else
                    {
                        Separator = new Cap(values[key].ToString());
                    }
                }
                else if (Regex.IsMatch("cap", pattern, RegexOptions.IgnoreCase))
                {
                    if (values[key] is Cap)
                    {
                        Cap = (Cap)values[key];
                    }
                    else if (values[key] is Array && ((Array)values[key]).Length > 1)
                    {
                        var kv = (Array)values[key];
                        Cap = new Cap(kv.GetValue(0).ToString(), kv.GetValue(1).ToString());
                    }
                    else
                    {
                        Cap = new Cap(values[key].ToString());
                    }
                }
                else if (Regex.IsMatch("persist", pattern, RegexOptions.IgnoreCase))
                {
                    PersistentColor = LanguagePrimitives.ConvertTo<bool>(values[key]);
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
        public Block(object @object)
        {
            var cap = new Cap();
            var sep = new Cap();

            var chars = Pansies.Entities.ExtendedCharacters;
            if (chars.ContainsKey("ColorSeparator"))
            {
                cap.Right = chars["ColorSeparator"];
            }
            if (chars.ContainsKey("ReverseColorSeparator"))
            {
                cap.Left = chars["ReverseColorSeparator"];
            }
            if (chars.ContainsKey("Separator"))
            {
                sep.Right = chars["Separator"];
            }
            if (chars.ContainsKey("ReverseSeparator"))
            {
                sep.Left = chars["ReverseSeparator"];
            }

            Cap = cap;
            Separator = sep;
            Object = @object;
        }

        public object Cache { get; private set; }
        private object CacheKey;
        public object Invoke(object cacheKey = null)
        {
            // null forces re-evaluation
            if (cacheKey?.Equals(CacheKey) == true)
            {
                return Cache;
            }

            Cache = null;
            CacheKey = cacheKey ?? String.Empty;
            switch (Object)
            {
                case Space space:
                    State.Alignment = space switch
                    {
                        Space.RightAlign => Alignment.Right,
                        Space.NewLine => State.Alignment = Alignment.Left,
                        _ => State.Alignment
                    };
                    Cache = Object;
                    break;
                case null:
                    break;
                default:
                    Cache = ConvertToString(Object, Separator.ToString());
                    if (string.IsNullOrEmpty(Cache.ToString()))
                    {
                        Cache = null;
                    }
                    break;
            }

            return Cache;
        }

        public override string ToString()
        {
            return GetString(ForegroundColor, BackgroundColor, Invoke(null), Cap.ToString(), Clear, Entities, PersistentColor);
        }

        public string ToLine(RgbColor otherBackground, object cacheKey = null)
        {
            return GetString(ForegroundColor, BackgroundColor, Invoke(cacheKey), Cap.ToString(), Clear, Entities, PersistentColor, otherBackground);
        }

        public static string GetString(RgbColor foreground, RgbColor background, object @object, string cap = null, bool clear = false, bool entities = true, bool persistentColor = true, RgbColor otherBackground = null)
        {
            var output = new StringBuilder();
            if (@object is Space space)
            {
                switch (space)
                {
                    case Space.Spacer:
                        cap = "\u001b[7m" + cap + "\u001b[27m";
                        @object = string.Empty;
                        background = otherBackground;
                        foreground = otherBackground = null;
                        break;
                    case Space.RightAlign:
                        return null;
                    case Space.NewLine:
                        return null;
                }
            }

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
                output.Append("\u001b[39m");
            }

            var color = new StringBuilder();
            if (null != foreground)
            {
                // There was a bug in Conhost where an advanced 48;2 RGB code followed by a console code wouldn't render the RGB value
                // So we try to put the ConsoleColor first, if it's there ...
                if (foreground.Mode == ColorMode.ConsoleColor)
                {
                    color.Append(foreground.ToVtEscapeSequence(false));
                    if (null != background)
                    {
                        color.Append(background.ToVtEscapeSequence(true));
                    }
                }
                else
                {
                    if (null != background)
                    {
                        color.Append(background.ToVtEscapeSequence(true));
                    }
                    color.Append(foreground.ToVtEscapeSequence(false));
                }
            }
            else if (null != background)
            {
                color.Append(background.ToVtEscapeSequence(true));
            }

            output.Append(color.ToString());
            output.Append(@object.ToString());

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
                return Pansies.Entities.Decode(output.ToString());
            }
            else
            {
                return output.ToString();
            }
        }

        public bool Equals(Block other)
        {
            return other != null &&
                (Object == other.Object &&
                    ForegroundColor == other.ForegroundColor &&
                    BackgroundColor == other.BackgroundColor) &&
                Separator.Equals(other.Separator) &&
                Cap.Equals(other.Cap);
        }

        public string ToPsMetadata() {
            return  "ForegroundColor:" + ForegroundColor?.ToString() +
                    "\nBackgroundColor:" + BackgroundColor?.ToString() +
                    "\nElevatedForegroundColor:" + ElevatedForegroundColor?.ToString() +
                    "\nElevatedBackgroundColor:" + ElevatedBackgroundColor?.ToString() +
                    "\nErrorForegroundColor:" + ErrorForegroundColor?.ToString() +
                    "\nErrorBackgroundColor:" + ErrorBackgroundColor?.ToString() +
                    "\nSeparator:" + Separator.ToPsMetadata() +
                    "\nCap:" + Cap.ToPsMetadata() +
                    "\nClear:" + (Clear ? 1 : 0) +
                    "\nEntities:" + (Entities ? 1 : 0)+
                    "\nPersist:" + (PersistentColor ? 1 : 0)+
                    "\nObject:" + (
                        Object is Space space ? space switch
                        {
                            Space.Spacer => "\" \"",
                            Space.NewLine => "\"`n\"",
                            Space.RightAlign => "\"`t\"",
                            _ => "\" \""
                        } :
                        // no need to mess with the quotes, because we'll end up in a @'here'@ string
                        Object is ScriptBlock script ? "{" + script.ToString() + "}" :
                        Object.ToString());
        }
        public void FromPsMetadata(string Metadata) {
            var data = Metadata.Split('\n',12)
                .Select(x => x.Split(':',2))
                .ToDictionary(x => x[0], x => (object)x[1]);

            string @object = (string)data["Object"];

            // transform the Caps separately
            Cap.FromPsMetadata((string)data["Cap"]);
            data.Remove("Cap");

            Separator.FromPsMetadata((string)data["Separator"]);
            data.Remove("Separator");
            // strip the null colors
            var empties = data.Where( x => x.Value.ToString().Length == 0).Select( x => x.Key);
            foreach(var empty in empties)
            {
                data.Remove(empty);
            }

            if (@object.StartsWith("{") && @object.EndsWith("}")) {
                data["Object"] = ScriptBlock.Create(@object.Substring(1, @object.Length - 2));
            }
            FromDictionary(data);
        }
    }
}
