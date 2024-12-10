CREATE OR ALTER PROCEDURE QueryRoomFees
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
        fee.id AS fee_id,
        fee.name AS fee_name,
        fee.lower AS fee_lower,
        fee.upper AS fee_upper,
        fee.per_area AS fee_per_area,
        fee.per_motorbike AS fee_per_motorbike,
        fee.per_car AS fee_per_car,
        fee.deadline AS fee_deadline,
        fee.description AS fee_description,
        fee.flags AS fee_flags,
        fee.lower + rooms.area / 100 * fee.per_area + fee.per_motorbike * rooms.motorbike + fee.per_car * rooms.car AS lower_bound,
        fee.upper + rooms.area / 100 * fee.per_area + fee.per_motorbike * rooms.motorbike + fee.per_car * rooms.car AS upper_bound,
        payments.id AS payment_id,
        payments.room AS payment_room,
        payments.amount AS payment_amount,
        payments.fee_id AS payment_fee_id
    FROM fee
    INNER JOIN rooms ON rooms.room = @Room
    LEFT JOIN payments ON payments.fee_id = fee.id AND payments.room = @Room
    WHERE fee.id >= @FromId AND fee.id <= @ToId AND (
        @Paid IS NULL
        OR (@Paid = 0 AND payments.id IS NULL)
        OR (@Paid = 1 AND payments.id IS NOT NULL)
    )
    ORDER BY fee.id
    OFFSET @Offset ROWS
    FETCH NEXT @FetchNext ROWS ONLY
END
