CREATE OR ALTER PROCEDURE CountRooms
    @Room SMALLINT,
    @Floor SMALLINT
AS
BEGIN
    SET NOCOUNT ON;

	WITH all_rooms (room) AS (
		SELECT room FROM rooms
        UNION
        SELECT room FROM accounts WHERE approved = 1
	)
	SELECT COUNT(1) FROM all_rooms
	WHERE (@Room IS NULL OR @Room = room) AND (@Floor IS NULL OR @Floor = room / 100)
END
