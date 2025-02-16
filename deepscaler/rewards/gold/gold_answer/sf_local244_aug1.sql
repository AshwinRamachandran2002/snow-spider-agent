-- Task: Classify the tracks into 'Short', 'Medium', or 'Long' based on their durations, and output the number of tracks in each category.
WITH temp_t1 AS (
    SELECT 
        MIN("Milliseconds") AS Limit1,
        AVG("Milliseconds") AS avg_milliseconds,
        (avg_milliseconds + MIN("Milliseconds")) / 2 AS Limit2,
        (MAX("Milliseconds") + avg_milliseconds) / 2 AS Limit3,
        MAX("Milliseconds") AS Limit4
    FROM MUSIC.MUSIC.TRACK
),
categ AS (
    SELECT 
        "TrackId",
        CASE 
            WHEN t."Milliseconds" < (SELECT Limit2 FROM temp_t1) THEN 'Short'
            WHEN t."Milliseconds" < (SELECT Limit3 FROM temp_t1) THEN 'Medium'
            WHEN t."Milliseconds" <= (SELECT Limit4 FROM temp_t1) THEN 'Long'
        END AS LengthCateg
    FROM MUSIC.MUSIC.TRACK t
)
SELECT 
    c.LengthCateg,
    COUNT(*) AS NumTracks
FROM categ c
GROUP BY c.LengthCateg
ORDER BY c.LengthCateg;