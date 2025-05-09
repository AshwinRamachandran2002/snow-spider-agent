WITH track_duration AS (
    SELECT
        "TrackId",
        "Milliseconds",
        "Milliseconds" / 60000.0                             AS minutes,
        CASE
            WHEN "Milliseconds" < 180000 THEN 'Short'        -- < 3 minutes
            WHEN "Milliseconds" <= 300000 THEN 'Medium'      -- 3–5 minutes
            ELSE 'Long'                                      -- > 5 minutes
        END                                                  AS category
    FROM "Track"
),
track_revenue AS (
    SELECT
        "TrackId",
        SUM("UnitPrice" * "Quantity") AS revenue
    FROM "InvoiceLine"
    GROUP BY "TrackId"
),
track_combined AS (
    SELECT
        td.category,
        td.minutes,
        COALESCE(tr.revenue, 0) AS revenue
    FROM track_duration td
    LEFT JOIN track_revenue tr USING ("TrackId")
)
SELECT
    category                          AS "DurationCategory",
    ROUND(MIN(minutes), 4)            AS "MinMinutes",
    ROUND(MAX(minutes), 4)            AS "MaxMinutes",
    ROUND(SUM(revenue), 4)            AS "TotalRevenue"
FROM track_combined
GROUP BY category
ORDER BY category;