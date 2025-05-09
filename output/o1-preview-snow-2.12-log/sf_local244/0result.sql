WITH stats AS (
    SELECT 
        MIN("Milliseconds") AS min_ms,
        AVG("Milliseconds") AS avg_ms,
        MAX("Milliseconds") AS max_ms
    FROM MUSIC.MUSIC.TRACK
),
midpoints AS (
    SELECT 
        min_ms,
        avg_ms,
        max_ms,
        (min_ms + avg_ms) / 2 AS mid_min_avg,
        (avg_ms + max_ms) / 2 AS mid_avg_max
    FROM stats
),
classified_tracks AS (
    SELECT 
        t."TrackId",
        t."Milliseconds",
        t."Name",
        (t."Milliseconds" / 60000.0) AS "DurationMinutes",
        CASE
            WHEN t."Milliseconds" <= m.mid_min_avg THEN 'Short'
            WHEN t."Milliseconds" > m.mid_min_avg AND t."Milliseconds" <= m.mid_avg_max THEN 'Medium'
            ELSE 'Long'
        END AS "Category"
    FROM MUSIC.MUSIC.TRACK t
    CROSS JOIN midpoints m
),
track_revenue AS (
    SELECT 
        il."TrackId",
        SUM(il."UnitPrice" * il."Quantity") AS "Revenue"
    FROM MUSIC.MUSIC.INVOICELINE il
    GROUP BY il."TrackId"
),
tracks_with_revenue AS (
    SELECT 
        ct."Category",
        ct."DurationMinutes",
        COALESCE(tr."Revenue", 0) AS "Revenue"
    FROM classified_tracks ct
    LEFT JOIN track_revenue tr ON ct."TrackId" = tr."TrackId"
)
SELECT
    "Category",
    ROUND(MIN("DurationMinutes"), 4) AS "Min_time_minutes",
    ROUND(MAX("DurationMinutes"), 4) AS "Max_time_minutes",
    ROUND(SUM("Revenue"), 4) AS "Total_revenue"
FROM tracks_with_revenue
GROUP BY "Category"
ORDER BY "Category";