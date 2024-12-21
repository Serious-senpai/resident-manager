CREATE OR ALTER PROCEDURE CountPaymentStatus
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

    IF @Room IS NULL
    BEGIN
        DECLARE @PaidPaymentStatus BIGINT = 0
        IF @Paid IS NOT NULL
            SET @PaidPaymentStatus = (
                SELECT COUNT(1)
                FROM payments
                WHERE fee_id >= @FromId AND fee_id <= @ToId
            )

        IF @Paid IS NULL OR @Paid = 0
            BEGIN
                DECLARE @RoomCount BIGINT = (SELECT COUNT(1) FROM rooms)
                DECLARE @FeeCount BIGINT = (SELECT COUNT(1) FROM fees WHERE fees.id >= @FromId AND fees.id <= @ToId)
                DECLARE @Result BIGINT = @RoomCount * @FeeCount

                IF @Paid IS NULL
                    SELECT @Result

                ELSE
                    SELECT @Result - @PaidPaymentStatus
            END

        ELSE
            SELECT @PaidPaymentStatus

    END
    ELSE
        SELECT COUNT(1)
        FROM fees
        WHERE fees.id >= @FromId AND fees.id <= @ToId AND (
            @Paid IS NULL
            OR (@Paid = 0 AND NOT EXISTS (SELECT 1 FROM payments WHERE fee_id = fees.id AND room = @Room))
            OR (@Paid = 1 AND EXISTS (SELECT 1 FROM payments WHERE fee_id = fees.id AND room = @Room))
        )
END
