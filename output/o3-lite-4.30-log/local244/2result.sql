SELECT  Category                                                     AS category,
        ROUND(MIN_MS / 60000.0, 4)                                   AS min_duration_minutes,
        ROUND(MAX_MS / 60000.0, 4)                                   AS max_duration_minutes,
        ROUND(Total_Revenue, 4)                                      AS total_revenue
FROM (
        SELECT  CASE
                    WHEN t."Milliseconds" < 180000  THEN 'short'
                    WHEN t."Milliseconds" <= 300000 THEN 'medium'
                    ELSE                               'long'
                END                                  AS Category,
                MIN(t."Milliseconds")                AS MIN_MS,
                MAX(t."Milliseconds")                AS MAX_MS,
                SUM(il."UnitPrice" * il."Quantity")  AS Total_Revenue
        FROM    "Track"        t
        JOIN    "InvoiceLine"  il ON il."TrackId" = t."TrackId"
        GROUP BY Category
)
ORDER BY CASE Category
             WHEN 'short'  THEN 1
             WHEN 'medium' THEN 2
             WHEN 'long'   THEN 3
         END;