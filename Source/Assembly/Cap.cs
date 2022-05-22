using System;

namespace PoshCode.PowerLine
{
    public struct Cap
    {
        public string Left;

        public string Right;

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
    }
}
