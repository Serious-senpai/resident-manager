CREATE OR ALTER PROCEDURE DeleteRoom
    @Rooms BIGINTARRAY READONLY
AS
    DELETE FROM rooms
    WHERE room IN (
        SELECT value FROM @Rooms
    )
