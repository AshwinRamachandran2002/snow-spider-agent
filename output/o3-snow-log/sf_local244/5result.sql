/* 1) get global duration statistics              */
/* 2) classify every track into Short/Medium/Long */
/* 3) calculate revenue per track                 */
/* 4) aggregate by category                       */
WITH duration_stats AS (
    SELECT
        MIN("Milliseconds") AS min_ms,
        AVG("Milliseconds") AS avg_ms,
        MAX("Milliseconds") AS max_ms
    FROM MUSIC.MUSIC.TRACK
),
track_categorized AS (
    SELECT
        t."TrackId",
        t."Milliseconds",
        CASE
            WHEN t."Milliseconds" < (ds.min_ms + ds.avg_ms) / 2  THEN 'Short'
            WHEN t."Milliseconds" < (ds.avg_ms + ds.max_ms) / 2  THEN 'Medium'
            ELSE                                                    'Long'
        END AS length_category
    FROM MUSIC.MUSIC.TRACK AS t
    CROSS JOIN duration_stats AS ds
),
track_revenue AS (
    SELECT
        il."TrackId",
        SUM(il."UnitPrice" * il."Quantity") AS revenue
    FROM MUSIC.MUSIC.INVOICELINE AS il
    GROUP BY il."TrackId"
),
category_agg AS (
    SELECT
        tc.length_category,
        MIN(tc."Milliseconds") / 60000.0 AS min_time_minutes,
        MAX(tc."Milliseconds") / 60000.0 AS max_time_minutes,
        COALESCE(SUM(tr.revenue), 0)     AS total_revenue
    FROM track_categorized AS tc
    LEFT JOIN track_revenue AS tr
           ON tc."TrackId" = tr."TrackId"
    GROUP BY tc.length_category
)
SELECT
    length_category                    AS "Category",
    ROUND(min_time_minutes, 4)         AS "Min_Time_Minutes",
    ROUND(max_time_minutes, 4)         AS "Max_Time_Minutes",
    ROUND(total_revenue,    4)         AS "Total_Revenue"
FROM category_agg
ORDER BY length_category;