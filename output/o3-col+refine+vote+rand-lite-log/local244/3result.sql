SELECT
    cat."LengthCategory",
    ROUND(MIN(cat."Minutes"), 4) AS "MinMinutes",
    ROUND(MAX(cat."Minutes"), 4) AS "MaxMinutes",
    ROUND(SUM(cat."LineRevenue"), 4) AS "TotalRevenue"
FROM (
    SELECT
        CASE
            WHEN t."Milliseconds" < 180000            THEN 'Short'
            WHEN t."Milliseconds" <= 300000           THEN 'Medium'
            ELSE                                          'Long'
        END                                    AS "LengthCategory",
        t."Milliseconds" / 60000.0             AS "Minutes",
        COALESCE(il."UnitPrice" * il."Quantity", 0) AS "LineRevenue"
    FROM "Track"        AS t
    LEFT JOIN "InvoiceLine" AS il ON il."TrackId" = t."TrackId"
) AS cat
GROUP BY cat."LengthCategory";