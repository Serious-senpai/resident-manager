CREATE OR ALTER PROCEDURE CountRoomFees
    @Room SMALLINT,
    @Paid BIT,
    @CreatedAfter DATETIME2,
    @CreatedBefore DATETIME2
AS
BEGIN
    SET NOCOUNT ON

    DECLARE @Epoch DATETIME2
    SELECT @Epoch = value FROM config_datetime2 WHERE name = 'epoch'

    DECLARE @FromId BIGINT = DATEDIFF_BIG(MILLISECOND, @Epoch, @CreatedAfter) << 16
    DECLARE @ToId BIGINT = (DATEDIFF_BIG(MILLISECOND, @Epoch, @CreatedBefore) << 16) | 0xFFFF

    SELECT COUNT(1)
    FROM fees
    WHERE fees.id >= @FromId AND fees.id <= @ToId AND (
        @Paid IS NULL
        OR (@Paid = 0 AND NOT EXISTS (SELECT 1 FROM payments WHERE fee_id = fees.id AND room = @Room))
        OR (@Paid = 1 AND EXISTS (SELECT 1 FROM payments WHERE fee_id = fees.id AND room = @Room))
    )
END
