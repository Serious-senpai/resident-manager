CREATE OR ALTER PROCEDURE QueryRooms
    @Room SMALLINT,
    @Floor SMALLINT,
    @Offset INT,
    @FetchNext INT
AS
BEGIN
    SET NOCOUNT ON;

	WITH all_rooms (room, area, motorbike, car, residents) AS (
		SELECT
			IIF(rooms.room IS NULL, approved_residents.room, rooms.room),
			area,
			motorbike,
			car,
			IIF(residents IS NULL, 0, residents)
		FROM rooms
		FULL OUTER JOIN (
			SELECT room, COUNT(1) AS residents
			FROM accounts
			WHERE approved = 1
			GROUP BY room
		) AS approved_residents ON rooms.room = approved_residents.room
	)
	SELECT * FROM all_rooms
	WHERE (@Room IS NULL OR @Room = room) AND (@Floor IS NULL OR @Floor = room / 100)
    ORDER BY room
    OFFSET @Offset ROWS
    FETCH NEXT @FetchNext ROWS ONLY
END
