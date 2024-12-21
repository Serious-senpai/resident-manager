CREATE OR ALTER PROCEDURE QueryPaymentStatus
    @Room SMALLINT,
    @Paid BIT,
    @CreatedAfter DATETIME2,
    @CreatedBefore DATETIME2,
    @Offset INT,
    @FetchNext INT
AS
BEGIN
    SET NOCOUNT ON

    DECLARE @Epoch DATETIME2
    SELECT @Epoch = value FROM config_datetime2 WHERE name = 'epoch'

    DECLARE @FromId BIGINT = DATEDIFF_BIG(MILLISECOND, @Epoch, @CreatedAfter) << 16
    DECLARE @ToId BIGINT = (DATEDIFF_BIG(MILLISECOND, @Epoch, @CreatedBefore) << 16) | 0xFFFF

    SELECT
        fees.id AS fee_id,
        fees.name AS fee_name,
        fees.lower AS fee_lower,
        fees.upper AS fee_upper,
        fees.per_area AS fee_per_area,
        fees.per_motorbike AS fee_per_motorbike,
        fees.per_car AS fee_per_car,
        fees.deadline AS fee_deadline,
        fees.description AS fee_description,
        fees.flags AS fee_flags,
        fees.lower + rooms.area / 100 * fees.per_area + fees.per_motorbike * rooms.motorbike + fees.per_car * rooms.car AS lower_bound,
        fees.upper + rooms.area / 100 * fees.per_area + fees.per_motorbike * rooms.motorbike + fees.per_car * rooms.car AS upper_bound,
        payments.id AS payment_id,
        payments.room AS payment_room,
        payments.amount AS payment_amount,
        payments.fee_id AS payment_fee_id,
        rooms.room AS room
    FROM fees
    INNER JOIN rooms ON (@Room IS NULL OR @Room = rooms.room)
    LEFT JOIN payments ON payments.fee_id = fees.id AND payments.room = rooms.room
    WHERE fees.id >= @FromId AND fees.id <= @ToId AND (
        @Paid IS NULL
        OR (@Paid = 0 AND payments.id IS NULL)
        OR (@Paid = 1 AND payments.id IS NOT NULL)
    )
    ORDER BY fees.id DESC
    OFFSET @Offset ROWS
    FETCH NEXT @FetchNext ROWS ONLY
END
