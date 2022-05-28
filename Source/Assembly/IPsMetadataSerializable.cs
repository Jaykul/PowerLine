namespace PoshCode.PowerLine
{
    public interface IPsMetadataSerializable
    {
        string ToPsMetadata();
        void FromPsMetadata(string metadata);
    }
}