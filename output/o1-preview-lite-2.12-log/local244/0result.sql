SELECT
    Track_Length_Category,
    ROUND(MIN(DurationMinutes), 4) AS Min_Time,
    ROUND(MAX(DurationMinutes), 4) AS Max_Time,
    ROUND(SUM(TotalRevenue), 4) AS Total_Revenue
FROM
    (
        SELECT
            t."TrackId",
            t."Name",
            t."Milliseconds",
            t."Milliseconds" / 60000.0 AS DurationMinutes,
            CASE
                WHEN t."Milliseconds" < 120000 THEN 'short'
                WHEN t."Milliseconds" BETWEEN 120000 AND 300000 THEN 'medium'
                ELSE 'long'
            END AS Track_Length_Category,
            COALESCE(ts.TotalRevenue, 0) AS TotalRevenue
        FROM
            "Track" t
        LEFT JOIN (
            SELECT
                "TrackId",
                SUM("Quantity" * "UnitPrice") AS TotalRevenue
            FROM
                "InvoiceLine"
            GROUP BY
                "TrackId"
        ) ts ON t."TrackId" = ts."TrackId"
    ) sub
GROUP BY
    Track_Length_Category;