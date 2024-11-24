CREATE OR ALTER PROCEDURE QueryRoomFee
    @Room SMALLINT,
    @CreatedFrom DATETIME2,
    @CreatedTo DATETIME2,
    @Offset INT,
    @FetchNext INT
AS
BEGIN
    DECLARE @Epoch DATETIME2
    SELECT @Epoch = value FROM config_datetime2 WHERE name = 'epoch'

    DECLARE @FromId BIGINT = DATEDIFF_BIG(MILLISECOND, @Epoch, @CreatedFrom) << 16
    DECLARE @ToId BIGINT = (DATEDIFF_BIG(MILLISECOND, @Epoch, @CreatedTo) << 16) | 0xFFFF

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
        fee.lower + fee.per_area * rooms.area + fee.per_motorbike * rooms.motorbike + fee.per_car * rooms.car AS lower_bound,
        fee.upper + fee.per_area * rooms.area + fee.per_motorbike * rooms.motorbike + fee.per_car * rooms.car AS upper_bound,
        payment.id AS payment_id,
        payment.room AS payment_room,
        payment.amount AS payment_amount,
        payment.fee_id AS payment_fee_id
    FROM fee
    INNER JOIN rooms ON rooms.room = @Room
    LEFT JOIN payment ON payment.fee_id = fee.id AND payment.room = @Room
    WHERE fee.id NOT IN (
        SELECT fee_id FROM payments
        WHERE room = @Room
    ) AND fee.id >= @FromId AND fee.id <= @ToId
    ORDER BY fee.id
    OFFSET @Offset ROWS
    FETCH NEXT @FetchNext ROWS ONLY
END
