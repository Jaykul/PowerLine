using System;

namespace PoshCode.PowerLine
{
    public struct Separator
    {
        public string Left;

        public string Right;

        public Separator(string left = " ", string right = null)
        {
            Left = !String.IsNullOrEmpty(left) ? left : " ";
            Right = !String.IsNullOrEmpty(right) ? right : Left;
        }

        public override string ToString()
        {
            return State.Alignment == Alignment.Left ? Left : Right;
        }
    }
}
