using System;

namespace PoshCode.PowerLine
{
    public struct Cap : IEquatable<Cap>, IPsMetadataSerializable
    {
        public string Left { get; set; }

        public string Right { get; set; }

        public Cap(string left = " ", string right = null)
        {
            left = !String.IsNullOrEmpty(left) ? left : " ";
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
                Right = right;
            }
        }

        public override string ToString()
        {
            // If we're right-aligned, use the LEFT cap, and vice-versa
            return State.Alignment == Alignment.Right ? Left : Right;
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

        public bool Equals(Cap other)
        {
            return this.Left.Equals(other.Left, StringComparison.Ordinal) && this.Right.Equals(other.Right, StringComparison.Ordinal);
        }

        public override bool Equals(object obj)
        {
            return obj is Cap cap && this.Left.Equals(cap.Left, StringComparison.Ordinal) && this.Right.Equals(cap.Right, StringComparison.Ordinal);
        }

        public override int GetHashCode()
        {
            return (Left + Right).GetHashCode();
        }

        public static bool operator ==(Cap left, Cap right)
        {
            return left.Equals(right);
        }

        public static bool operator !=(Cap left, Cap right)
        {
            return !(left == right);
        }
    }
}
