WITH track_stats AS (               -- overall duration statistics
    SELECT
        MIN("Milliseconds")                       AS min_ms,
        AVG("Milliseconds")                       AS avg_ms,
        MAX("Milliseconds")                       AS max_ms
    FROM  MUSIC.MUSIC."TRACK"
), thresholds AS (                 -- compute the two mid-points
    SELECT
        min_ms,
        avg_ms,
        max_ms,
        (min_ms + avg_ms) / 2      AS mid1,
        (avg_ms + max_ms) / 2      AS mid2
    FROM track_stats
), tracks_categorized AS (          -- label every track
    SELECT
        t."TrackId",
        t."Milliseconds"            AS duration_ms,
        CASE
            WHEN t."Milliseconds" <  th.mid1 THEN 'Short'
            WHEN t."Milliseconds" <  th.mid2 THEN 'Medium'
            ELSE                              'Long'
        END                        AS category
    FROM  MUSIC.MUSIC."TRACK"  t
    CROSS JOIN thresholds   th
), track_revenue AS (               -- revenue per track
    SELECT
        tc.category,
        tc.duration_ms,
        SUM(COALESCE(il."UnitPrice",0) * COALESCE(il."Quantity",0))  AS revenue
    FROM  tracks_categorized  tc
    LEFT JOIN MUSIC.MUSIC."INVOICELINE"  il
           ON il."TrackId" = tc."TrackId"
    GROUP BY
        tc.category,
        tc.duration_ms
)
SELECT
    category                                           AS "CATEGORY",
    ROUND(MIN(duration_ms) / 60000.0 , 4)              AS "MIN_MINUTES",
    ROUND(MAX(duration_ms) / 60000.0 , 4)              AS "MAX_MINUTES",
    ROUND(SUM(revenue)           , 4)                  AS "TOTAL_REVENUE"
FROM   track_revenue
GROUP  BY category
ORDER  BY CASE category WHEN 'Short' THEN 1
                        WHEN 'Medium' THEN 2
                        ELSE 3 END;