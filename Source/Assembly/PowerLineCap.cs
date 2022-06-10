using System;

namespace PoshCode.PowerLine
{
    public class PowerLineCap : IEquatable<PowerLineCap>, IPsMetadataSerializable
    {
        public string Left { get; set; }

        public string Right { get; set; }

        public PowerLineCap(string caps = " ")
        {
            caps = !String.IsNullOrEmpty(caps) ? PoshCode.Pansies.Entities.Decode(caps) : " ";
            if (caps.Length > 1)
            {
                Left = char.IsSurrogate(caps, 0) ? char.ConvertFromUtf32(char.ConvertToUtf32(caps, 1)) : caps.Substring(0, 1);
                Right = char.IsSurrogate(caps, Left.Length) ? char.ConvertFromUtf32(char.ConvertToUtf32(caps, Left.Length)) : caps.Substring(Left.Length, 1);
            }
            else
            {
                Right = Left = caps;
            }
        }

        public PowerLineCap(string left, string right)
        {
            left = !String.IsNullOrEmpty(left) ? PoshCode.Pansies.Entities.Decode(left) : " ";
            if (right == null)
            {
                if (left.Length > 1)
                {
                    Left  = char.IsSurrogate(left, 0) ? char.ConvertFromUtf32(char.ConvertToUtf32(left, 1)) : left.Substring(0, 1);
                    Right = char.IsSurrogate(left, Left.Length) ? char.ConvertFromUtf32(char.ConvertToUtf32(left, Left.Length)) : left.Substring(Left.Length, 1);
                }
                else
                {
                    Right = Left = left;
                }
            }
            else
            {
                Left = left;
                Right = PoshCode.Pansies.Entities.Decode(right);
            }
        }

        public override string ToString()
        {
            // If we're right-aligned, use the right cap, and vice-versa
            return State.Alignment == Alignment.Right ? Right : Left;
        }

        public string ToPsMetadata()
        {
            return Left + "\u200D" + Right;
        }

        public void FromPsMetadata(string metadata)
        {
            var caps = metadata.Split( new char[] { '\u200D' }, 2);
            Left = caps[0];
            Right = caps[1];
        }

        public bool Equals(PowerLineCap other)
        {
            return this.Left.Equals(other.Left, StringComparison.Ordinal) && this.Right.Equals(other.Right, StringComparison.Ordinal);
        }

        public override bool Equals(object obj)
        {
            return obj is PowerLineCap cap && this.Left.Equals(cap.Left, StringComparison.Ordinal) && this.Right.Equals(cap.Right, StringComparison.Ordinal);
        }

        public override int GetHashCode()
        {
            return (Left + Right).GetHashCode();
        }

        public static bool operator ==(PowerLineCap left, PowerLineCap right)
        {
            return left.Equals(right);
        }

        public static bool operator !=(PowerLineCap left, PowerLineCap right)
        {
            return !(left == right);
        }
    }
}
