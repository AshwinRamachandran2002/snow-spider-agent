WITH track_minutes AS (
    SELECT
        t."TrackId",
        t."Milliseconds" / 60000.0                              AS "Minutes",
        CASE
            WHEN t."Milliseconds" < 180000 THEN 'Short'
            WHEN t."Milliseconds" < 300000 THEN 'Medium'
            ELSE 'Long'
        END                                                   AS "LengthCategory"
    FROM "Track" AS t
),
track_revenue AS (
    SELECT
        il."TrackId",
        SUM(il."UnitPrice" * il."Quantity")                   AS "TrackRevenue"
    FROM "InvoiceLine" AS il
    GROUP BY il."TrackId"
),
track_data AS (
    SELECT
        tm."LengthCategory",
        tm."Minutes",
        COALESCE(tr."TrackRevenue", 0)                        AS "TrackRevenue"
    FROM track_minutes AS tm
    LEFT JOIN track_revenue AS tr
           ON tm."TrackId" = tr."TrackId"
)
SELECT
    td."LengthCategory",
    ROUND(MIN(td."Minutes"), 4)      AS "MinMinutes",
    ROUND(MAX(td."Minutes"), 4)      AS "MaxMinutes",
    ROUND(SUM(td."TrackRevenue"), 4) AS "TotalRevenue"
FROM track_data AS td
GROUP BY td."LengthCategory";