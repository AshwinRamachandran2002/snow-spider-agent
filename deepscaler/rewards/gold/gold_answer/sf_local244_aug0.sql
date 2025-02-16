-- Task: Classify tracks into 'Short', 'Medium', or 'Long' categories based on their durations calculated from the TRACK table. The thresholds for categorization are derived from the minimum, average, and maximum track durations as follows:
-- - Limit1: Minimum track duration.
-- - avg_milliseconds: Average track duration.
-- - Limit2: (Limit1 + avg_milliseconds) / 2.
-- - Limit3: (avg_milliseconds + maximum track duration) / 2.
-- - Limit4: Maximum track duration.
-- Assign each track to a category:
-- - 'Short' if duration < Limit2.
-- - 'Medium' if Limit2 <= duration < Limit3.
-- - 'Long' if Limit3 <= duration <= Limit4.
-- For each category, output the lower and upper duration limits in minutes ('From_Minutes' and 'To_Minutes'), the category name ('LengthCateg'), and the total revenue ('TotalPrice') computed as the sum of 'UnitPrice' multiplied by 'Quantity' from the INVOICELINE table. Group the results by the category and order by 'TotalPrice'.

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
    CASE 
        WHEN c.LengthCateg = 'Short' THEN (SELECT Limit1 / 60000.0 FROM temp_t1)
        WHEN c.LengthCateg = 'Medium' THEN (SELECT Limit2 / 60000.0 FROM temp_t1)
        WHEN c.LengthCateg = 'Long' THEN (SELECT Limit3 / 60000.0 FROM temp_t1)
    END AS From_Minutes,
    CASE 
        WHEN c.LengthCateg = 'Short' THEN (SELECT Limit2 / 60000.0 FROM temp_t1)
        WHEN c.LengthCateg = 'Medium' THEN (SELECT Limit3 / 60000.0 FROM temp_t1)
        WHEN c.LengthCateg = 'Long' THEN (SELECT Limit4 / 60000.0 FROM temp_t1)
    END AS To_Minutes,
    c.LengthCateg,
    SUM(i."UnitPrice" * i."Quantity") AS TotalPrice
FROM categ c
JOIN MUSIC.MUSIC.INVOICELINE i ON c."TrackId" = i."TrackId"
GROUP BY c.LengthCateg
HAVING c.LengthCateg IS NOT NULL
ORDER BY TotalPrice;