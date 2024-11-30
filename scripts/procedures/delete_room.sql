CREATE OR ALTER PROCEDURE DeleteRoom
    @Rooms BIGINTARRAY READONLY
AS
    SET NOCOUNT ON
    DELETE FROM rooms
    WHERE room IN (
        SELECT value FROM @Rooms
    )
