CREATE OR ALTER PROCEDURE GenerateId
    @Id BIGINT OUTPUT
AS
BEGIN
    SET NOCOUNT ON

    DECLARE @Epoch DATETIME2
    SELECT @Epoch = value FROM config_datetime2 WHERE name = 'epoch'

    DECLARE @Now DATETIME2 = SYSUTCDATETIME()
    DECLARE @TimestampMs BIGINT = DATEDIFF_BIG(MILLISECOND, @Epoch, @Now)
    DECLARE @TailTable TABLE (value BIGINT)

    UPDATE config_bigint
    SET value = (value + 1) & 0xFFFF
    OUTPUT DELETED.value INTO @TailTable
    WHERE name = 'id_counter'

    DECLARE @Tail BIGINT = (SELECT value FROM @TailTable)
    SET @Id = LEFT_SHIFT(@TimestampMs, 16) | @Tail
END
