CREATE OR ALTER PROCEDURE CreatePayment
    @Room SMALLINT,
    @Amount INT,
    @FeeId BIGINT
AS
BEGIN
    SET NOCOUNT ON
    DECLARE @Id BIGINT
    EXECUTE GenerateId @Id = @Id OUTPUT

    BEGIN TRANSACTION
        IF NOT EXISTS (SELECT 1 FROM rooms WHERE room = @Room)
            SELECT '01' AS code, 'Invalid room number' AS message

        ELSE IF NOT EXISTS (SELECT 1 FROM fees WHERE id = @FeeId)
            SELECT '01' AS code, 'Invalid fee ID' AS message

        ELSE IF EXISTS (SELECT 1 FROM payments WHERE room = @Room AND fee_id = @FeeId)
            SELECT '02' AS code, 'Payment has already been updated' AS message

        ELSE
        BEGIN
            INSERT INTO payments (id, room, amount, fee_id)
            VALUES (@Id, @Room, @Amount, @FeeId)

            SELECT '00' AS code, 'Payment was updated successfully' AS message
        END

    COMMIT TRANSACTION
END
