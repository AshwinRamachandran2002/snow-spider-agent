WITH stats AS (     -- overall duration statistics
    SELECT 
        MIN("Milliseconds") AS min_ms,
        AVG("Milliseconds") AS avg_ms,
        MAX("Milliseconds") AS max_ms
    FROM MUSIC.MUSIC."TRACK"
),

thresholds AS (     -- cut-off points for the three length categories
    SELECT
        min_ms,
        avg_ms,
        max_ms,
        (min_ms + avg_ms) / 2  AS short_upper,
        (avg_ms + max_ms) / 2  AS medium_upper
    FROM stats
),

track_classified AS (   -- assign every track to Short / Medium / Long
    SELECT
        t."TrackId",
        t."Milliseconds",
        t."Milliseconds" / 60000.0                       AS duration_minutes,
        CASE
            WHEN t."Milliseconds" <= th.short_upper  THEN 'Short'
            WHEN t."Milliseconds" <= th.medium_upper THEN 'Medium'
            ELSE 'Long'
        END                                             AS length_category
    FROM MUSIC.MUSIC."TRACK" t
    CROSS JOIN thresholds th
),

revenue_per_track AS (  -- total money earned by each track
    SELECT
        il."TrackId",
        SUM(il."Quantity" * il."UnitPrice") AS revenue
    FROM MUSIC.MUSIC."INVOICELINE" il
    GROUP BY il."TrackId"
),

track_info AS (         -- merge duration category with revenue
    SELECT
        tc.length_category,
        tc.duration_minutes,
        COALESCE(r.revenue, 0) AS revenue
    FROM track_classified tc
    LEFT JOIN revenue_per_track r
           ON tc."TrackId" = r."TrackId"
)

SELECT
    length_category,
    ROUND(MIN(duration_minutes), 4) AS min_minutes,
    ROUND(MAX(duration_minutes), 4) AS max_minutes,
    ROUND(SUM(revenue), 4)          AS total_revenue
FROM track_info
GROUP BY length_category
ORDER BY length_category;