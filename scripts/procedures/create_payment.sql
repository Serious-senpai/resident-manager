CREATE OR ALTER PROCEDURE CreatePayment
    @Room SMALLINT,
    @Amount INT,
    @FeeId BIGINT
AS
BEGIN
    BEGIN TRANSACTION

        DECLARE @Id BIGINT
        EXECUTE GenerateId @Id = @Id OUTPUT

        IF EXISTS (SELECT 1 FROM payments WHERE room = @Room AND fee_id = @FeeId)
            SELECT * FROM payments WHERE 1 = 0

        ELSE
            INSERT INTO payments (id, room, amount, fee_id)
            OUTPUT INSERTED.*
            VALUES (@Id, @Room, @Amount, @FeeId)

    COMMIT TRANSACTION
END
