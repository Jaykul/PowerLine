using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Management.Automation.Language;
using System.Text;
using System.Text.RegularExpressions;
using PoshCode.Pansies;

namespace PoshCode.PowerLine
{
    public class PowerLineBlock : PoshCode.Pansies.Text, IPsMetadataSerializable
    {
        public PowerLineCap Cap { get; set; }
        public new PowerLineCap Separator
        {
            get
            {
                return (PowerLineCap)base.Separator;
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
#pragma warning disable CA1720 // Identifier contains type name
        public new object Object
#pragma warning restore CA1720 // Identifier contains type name
        {
            get
            {
                return base.Object;
            }
            set
            {
                var spaceTest = value.ToString();
                if (spaceTest.Equals("\t", StringComparison.Ordinal) || spaceTest.Trim().Equals("\"`t\"", StringComparison.Ordinal))
                {
                    base.Object = Space.RightAlign;
                }
                else if (spaceTest.Equals("\n", StringComparison.Ordinal) || spaceTest.Trim().Equals("\"`n\"", StringComparison.Ordinal))
                {
                    base.Object = Space.NewLine;
                }
                else if (spaceTest.Equals(" ", StringComparison.Ordinal) || spaceTest.Trim().Equals("\" \"", StringComparison.Ordinal))
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
        public PowerLineBlock(IDictionary values) : this()
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
                else if (Regex.IsMatch("InputObject", pattern, RegexOptions.IgnoreCase) ||
                        Regex.IsMatch("text", pattern, RegexOptions.IgnoreCase) ||
                        Regex.IsMatch("Content", pattern, RegexOptions.IgnoreCase) ||
                        Regex.IsMatch("Object", pattern, RegexOptions.IgnoreCase))
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
                    if (values[key] is PowerLineCap)
                    {
                        Separator = (PowerLineCap)values[key];
                    }
                    else if (values[key] is Array array && array.Length > 1)
                    {
                        Separator = new PowerLineCap(array.GetValue(0).ToString(), array.GetValue(1).ToString());
                    }
                    else
                    {
                        Separator = new PowerLineCap(values[key].ToString());
                    }
                }
                else if (Regex.IsMatch("cap", pattern, RegexOptions.IgnoreCase))
                {
                    if (values[key] is PowerLineCap)
                    {
                        Cap = (PowerLineCap)values[key];
                    }
                    else if (values[key] is Array && ((Array)values[key]).Length > 1)
                    {
                        var kv = (Array)values[key];
                        Cap = new PowerLineCap(kv.GetValue(0).ToString(), kv.GetValue(1).ToString());
                    }
                    else if (values[key] is Array && ((Array)values[key]).Length == 1)
                    {
                        var kv = (Array)values[key];
                        Cap = new PowerLineCap(kv.GetValue(0).ToString());
                    }
                    else
                    {
                        Cap = new PowerLineCap(values[key].ToString());
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
        public PowerLineBlock() : this("") { }

        // Make sure we can output plain text
        public PowerLineBlock(object obj)
        {
            Cap = State.DefaultCap;
            Separator = State.DefaultSeparator;
            Object = obj;
        }

        // The Cache is always a string or a Space enum
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
                    switch(space)
                    {
                        case Space.RightAlign:
                            State.Alignment = Alignment.Right;
                            break;
                        case Space.NewLine:
                            State.Alignment = Alignment.Left;
                            break;
                    }
                    Cache = Object;
                    break;
                case null:
                    break;
                default:
                    Cache = ConvertToString(Object, Separator?.ToString());
                    if (string.IsNullOrEmpty(Cache?.ToString()))
                    {
                        Cache = null;
                    }
                    break;
            }

            return Cache;
        }

        public override string ToString()
        {
            return GetString(ForegroundColor, BackgroundColor, Invoke(null), Cap?.ToString(), Clear, Entities, PersistentColor);
        }

        public string ToLine(RgbColor otherBackground, object cacheKey = null)
        {
            return GetString(ForegroundColor, BackgroundColor, Invoke(cacheKey), Cap?.ToString(), Clear, Entities, PersistentColor, otherBackground);
        }

        public static string GetString(RgbColor foreground, RgbColor background, object obj, string cap = null, bool clear = false, bool entities = true, bool persistentColor = true, RgbColor otherBackground = null)
        {
            var output = new StringBuilder();
            if (obj is Space space)
            {
                switch (space)
                {
                    case Space.Spacer:
                        cap = "\u001b[7m" + cap + "\u001b[27m";
                        obj = string.Empty;
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
            output.Append(obj.ToString());

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

        public bool Equals(PowerLineBlock other)
        {
            return other != null &&
                (Object == other.Object &&
                    ForegroundColor == other.ForegroundColor &&
                    BackgroundColor == other.BackgroundColor) &&
                (Separator == null && other.Separator == null || Separator.Equals(other.Separator)) &&
                (Cap == null && other.Cap == null || Cap.Equals(other.Cap));
        }

        public override string ToPsMetadata() {

            var objectString = string.Empty;
            // ToDictionary and Constructor handle single-character strings (with quotes) for Space
            if (Object is Space space)
            {
                objectString = "\" \"";
                switch (space)
                {
                    case Space.Spacer:
                        objectString = "\" \"";
                        break;
                    case Space.NewLine:
                        objectString = "\"`n\"";
                        break;
                    case Space.RightAlign:
                        objectString = "\"`t\"";
                        break;
                }
            }
            else if (Object is ScriptBlock script)
            {
                objectString = "(ScriptBlock '" + script.ToString().Replace("\'","\'\'") + "')";
            }
            else
            {
                objectString = "\'" + Object.ToString().Replace("\'", "\'\'") + "\'";
            }

            return  "@{" +
                    (ForegroundColor is null ? "" : "\nForegroundColor='" + ForegroundColor.ToString() + "'") +
                    (BackgroundColor is null ? "" : "\nBackgroundColor='" + BackgroundColor.ToString() + "'") +
                    (ErrorForegroundColor is null ? "" : "\nErrorForegroundColor='" + ErrorForegroundColor.ToString() + "'") +
                    (ErrorBackgroundColor is null ? "" : "\nErrorBackgroundColor='" + ErrorBackgroundColor.ToString() + "'") +
                    (ElevatedForegroundColor is null ? "" : "\nElevatedForegroundColor='" + ElevatedForegroundColor.ToString() + "'") +
                    (ElevatedBackgroundColor is null ? "" : "\nElevatedBackgroundColor='" + ElevatedBackgroundColor.ToString() + "'") +
                    (Separator is null ? "" : "\nSeparator='" + Separator.ToPsMetadata() + "'") +
                    (Cap is null ? "" : "\nCap='" + Cap.ToPsMetadata() + "'") +
                    (Clear ? "\nClear=1" : "") +
                    (Entities ? "\nEntities=1" : "")  +
                    (PersistentColor ? "\nPersist=1" : "") +
                    "\nObject=" + objectString +
                    "\n}";
        }

        public override void FromPsMetadata(string metadata)
        {
            var ps = PowerShell.Create(RunspaceMode.CurrentRunspace);
            var languageMode = ps.Runspace.SessionStateProxy.LanguageMode;
            Hashtable data;
            try
            {
                ps.Runspace.SessionStateProxy.LanguageMode = PSLanguageMode.RestrictedLanguage;
                ps.AddScript(metadata, true);
                data = ps.Invoke<Hashtable>().FirstOrDefault();

                // transform the Caps separately
                if (data.Contains("Cap"))
                {
                    Cap = new PowerLineCap();
                    Cap.FromPsMetadata(data["Cap"].ToString());
                    data.Remove("Cap");
                }

                if (data.Contains("Separator"))
                {
                    Separator = new PowerLineCap();
                    Separator.FromPsMetadata(data["Separator"].ToString());
                    data.Remove("Separator");
                }

                FromDictionary(data);
            }
            finally
            {
                ps.Runspace.SessionStateProxy.LanguageMode = languageMode;
            }
        }
    }
}
