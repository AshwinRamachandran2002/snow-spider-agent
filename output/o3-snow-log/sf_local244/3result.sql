/*----------------------------------------------------------------------
   1) stats        : overall duration statistics and cut-off points
   2) track_cat    : every track tagged as SHORT / MEDIUM / LONG
   3) track_sales  : track-level rows with duration (in minutes) and
                     any revenue coming from invoice lines
   4) final select : min / max duration (minutes) and total revenue
                     per length category
------------------------------------------------------------------------*/
WITH stats AS (
    SELECT
        MIN("Milliseconds")                                         AS min_ms,
        AVG("Milliseconds")                                         AS avg_ms,
        MAX("Milliseconds")                                         AS max_ms,
        (MIN("Milliseconds") + AVG("Milliseconds")) / 2             AS mid1,
        (AVG("Milliseconds") + MAX("Milliseconds")) / 2             AS mid2
    FROM MUSIC.MUSIC."TRACK"
),
track_cat AS (
    SELECT
        t."TrackId",
        t."Milliseconds",
        CASE
            WHEN t."Milliseconds" <  s.mid1 THEN 'Short'
            WHEN t."Milliseconds" <  s.mid2 THEN 'Medium'
            ELSE                                 'Long'
        END                                                         AS category
    FROM MUSIC.MUSIC."TRACK"  t
    CROSS JOIN stats            s
),
track_sales AS (
    SELECT
        tc.category,
        tc."Milliseconds" / 60000.0                                 AS minutes,
        COALESCE(il."UnitPrice" * il."Quantity", 0)                 AS revenue
    FROM track_cat                          tc
    LEFT JOIN MUSIC.MUSIC."INVOICELINE"  il
           ON tc."TrackId" = il."TrackId"
)
SELECT
    category,
    ROUND(MIN(minutes), 4)  AS min_minutes,
    ROUND(MAX(minutes), 4)  AS max_minutes,
    ROUND(SUM(revenue), 4)  AS total_revenue
FROM track_sales
GROUP BY category
ORDER BY category;