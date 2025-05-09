WITH stats AS (
    SELECT 
        MIN("Milliseconds") AS min_ms,
        AVG("Milliseconds") AS avg_ms,
        MAX("Milliseconds") AS max_ms
    FROM MUSIC.MUSIC."TRACK"
),
edges AS (   -- limits that split the whole range in three
    SELECT 
        min_ms,
        avg_ms,
        max_ms,
        (min_ms + avg_ms) / 2     AS mid1,
        (avg_ms + max_ms) / 2     AS mid2
    FROM stats
),
track_cat AS (   -- every track classified as Short / Medium / Long
    SELECT
        t."TrackId",
        t."Milliseconds",
        CASE
            WHEN t."Milliseconds" <  e.mid1 THEN 'Short'
            WHEN t."Milliseconds" <  e.mid2 THEN 'Medium'
            ELSE                               'Long'
        END AS category
    FROM MUSIC.MUSIC."TRACK"  t
    CROSS JOIN edges          e
),
cat_durations AS (   -- min / max duration (ms) per category
    SELECT
        category,
        MIN("Milliseconds") AS min_ms_cat,
        MAX("Milliseconds") AS max_ms_cat
    FROM track_cat
    GROUP BY category
),
cat_revenue AS (     -- total revenue per category
    SELECT
        tc.category,
        SUM(il."UnitPrice" * il."Quantity") AS revenue
    FROM track_cat                  tc
    JOIN MUSIC.MUSIC."INVOICELINE"  il
          ON tc."TrackId" = il."TrackId"
    GROUP BY tc.category
)
SELECT
    cd.category                                   AS "TRACK_LENGTH_CATEGORY",
    ROUND(cd.min_ms_cat / 60000.0, 4)            AS "MIN_TIME_MINUTES",
    ROUND(cd.max_ms_cat / 60000.0, 4)            AS "MAX_TIME_MINUTES",
    ROUND(NVL(cr.revenue, 0), 4)                 AS "TOTAL_REVENUE"
FROM cat_durations  cd
LEFT JOIN cat_revenue cr
       ON cd.category = cr.category
ORDER BY "TRACK_LENGTH_CATEGORY";