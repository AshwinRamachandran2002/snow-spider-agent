WITH track_durations AS (
    SELECT
        "TrackId",
        ("Milliseconds" / 60000.0)                                           AS duration_minutes,
        CASE
            WHEN "Milliseconds" < 180000            THEN 'Short'            -- 0 – 3 minutes
            WHEN "Milliseconds" <= 300000           THEN 'Medium'           -- >3 – 5 minutes
            ELSE                                        'Long'              -- >5 minutes
        END                                                                 AS category
    FROM "Track"
),
sales AS (
    SELECT
        "TrackId",
        SUM("UnitPrice" * "Quantity") AS revenue
    FROM "InvoiceLine"
    GROUP BY "TrackId"
),
tracks_with_sales AS (
    SELECT
        td.category,
        td.duration_minutes,
        COALESCE(s.revenue, 0) AS revenue
    FROM track_durations td
    LEFT JOIN sales s ON td."TrackId" = s."TrackId"
)
SELECT
    category,
    ROUND(MIN(duration_minutes), 4) AS min_minutes,
    ROUND(MAX(duration_minutes), 4) AS max_minutes,
    ROUND(SUM(revenue), 2)          AS total_revenue
FROM tracks_with_sales
GROUP BY category
ORDER BY
    CASE category
        WHEN 'Short'  THEN 1
        WHEN 'Medium' THEN 2
        WHEN 'Long'   THEN 3
    END;