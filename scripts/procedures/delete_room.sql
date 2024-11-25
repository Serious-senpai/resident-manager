CREATE OR ALTER PROCEDURE DeleteRoom
    @Rooms BIGINTARRAY READONLY
AS
    DELETE FROM rooms
    WHERE id IN (
        SELECT value FROM @Rooms
    )
