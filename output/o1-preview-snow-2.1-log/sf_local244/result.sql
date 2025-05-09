WITH
    Thresholds AS (
        SELECT
            MIN("Milliseconds") AS "MinMs",
            AVG("Milliseconds") AS "AvgMs",
            MAX("Milliseconds") AS "MaxMs",
            (MIN("Milliseconds") + AVG("Milliseconds")) / 2 AS "Mid_MinAvg",
            (AVG("Milliseconds") + MAX("Milliseconds")) / 2 AS "Mid_AvgMax"
        FROM MUSIC.MUSIC.TRACK
    ),
    Track_Durations AS (
        SELECT
            T."TrackId",
            T."Milliseconds",
            T."Name",
            T."UnitPrice",
            (T."Milliseconds") / 60000.0 AS "DurationMinutes",
            CASE
                WHEN T."Milliseconds" >= (SELECT "MinMs" FROM Thresholds) AND T."Milliseconds" < (SELECT "Mid_MinAvg" FROM Thresholds) THEN 'Short'
                WHEN T."Milliseconds" >= (SELECT "Mid_MinAvg" FROM Thresholds) AND T."Milliseconds" < (SELECT "Mid_AvgMax" FROM Thresholds) THEN 'Medium'
                WHEN T."Milliseconds" >= (SELECT "Mid_AvgMax" FROM Thresholds) AND T."Milliseconds" <= (SELECT "MaxMs" FROM Thresholds) THEN 'Long'
            END AS "Category"
        FROM MUSIC.MUSIC.TRACK T
    ),
    Track_Revenue AS (
        SELECT
            TD."Category",
            TD."DurationMinutes",
            TD."TrackId",
            COALESCE(SUM(IL."UnitPrice" * IL."Quantity"), 0) AS "TotalRevenuePerTrack"
        FROM Track_Durations TD
        LEFT JOIN MUSIC.MUSIC.INVOICELINE IL
            ON TD."TrackId" = IL."TrackId"
        GROUP BY
            TD."Category",
            TD."DurationMinutes",
            TD."TrackId"
    ),
    Category_Summary AS (
        SELECT
            "Category",
            MIN("DurationMinutes") AS "Min_time_minutes",
            MAX("DurationMinutes") AS "Max_time_minutes",
            SUM("TotalRevenuePerTrack") AS "Total_revenue"
        FROM Track_Revenue
        GROUP BY "Category"
    )
SELECT
    "Category",
    ROUND("Min_time_minutes", 4) AS "Min_time_minutes",
    ROUND("Max_time_minutes", 4) AS "Max_time_minutes",
    ROUND("Total_revenue", 4) AS "Total_revenue"
FROM Category_Summary
ORDER BY "Category";