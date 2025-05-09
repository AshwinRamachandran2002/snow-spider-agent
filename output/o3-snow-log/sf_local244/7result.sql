/* 1) Work out overall duration statistics              */
/* 2) Classify every track as Short / Medium / Long      */
/* 3) Aggregate revenue (InvoiceLine) for every track    */
/* 4) Return, for every length-category,                 */
/*      – minimum time (minutes)                         */
/*      – maximum time (minutes)                         */
/*      – total revenue                                  */
WITH
/* ---------------------------------------------------- */
stats AS (   /* overall duration numbers (milliseconds) */
    SELECT
        MIN("Milliseconds")                                              AS min_ms ,
        AVG("Milliseconds")                                              AS avg_ms ,
        MAX("Milliseconds")                                              AS max_ms ,
        ( MIN("Milliseconds") + AVG("Milliseconds") ) / 2                AS midpoint1 ,
        ( AVG("Milliseconds") + MAX("Milliseconds") ) / 2                AS midpoint2
    FROM MUSIC.MUSIC."TRACK"
),

/* ---------------------------------------------------- */
track_class AS (   /* one row per track with a category */
    SELECT
        t."TrackId" ,
        t."Milliseconds" ,
        CASE
            WHEN t."Milliseconds" <  s.midpoint1 THEN 'Short'
            WHEN t."Milliseconds" <  s.midpoint2 THEN 'Medium'
            ELSE                                     'Long'
        END                                                     AS length_category
    FROM MUSIC.MUSIC."TRACK"  t
    CROSS JOIN stats          s
),

/* ---------------------------------------------------- */
track_revenue AS (       /* revenue per track           */
    SELECT
        il."TrackId" ,
        SUM( il."Quantity" * il."UnitPrice" )     AS track_revenue
    FROM MUSIC.MUSIC."INVOICELINE" il
    GROUP BY il."TrackId"
)

/* ---------------------------------------------------- */
SELECT
    tc.length_category                                                                    AS length_category ,
    ROUND( MIN(tc."Milliseconds") / 60000 , 4)                                            AS min_time_minutes ,
    ROUND( MAX(tc."Milliseconds") / 60000 , 4)                                            AS max_time_minutes ,
    ROUND( COALESCE( SUM( tr.track_revenue ) , 0 ) , 4)                                   AS total_revenue
FROM track_class   tc
LEFT JOIN track_revenue  tr
       ON  tc."TrackId" = tr."TrackId"
GROUP BY tc.length_category
ORDER BY tc.length_category;