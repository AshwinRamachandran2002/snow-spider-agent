WITH monthly_data AS (
    SELECT
        strftime('%Y', "insert_date") AS Year,
        strftime('%m', "insert_date") AS Month_Num,
        COUNT(*) AS Total_Cities_Added
    FROM "cities"
    WHERE strftime('%Y', "insert_date") BETWEEN '2021' AND '2023'
          AND strftime('%m', "insert_date") IN ('04', '05', '06')
    GROUP BY Year, Month_Num
),
running_totals AS (
    SELECT
        Year,
        Month_Num,
        Total_Cities_Added,
        SUM(Total_Cities_Added) OVER (PARTITION BY Year ORDER BY Month_Num) AS Running_Cumulative_Total
    FROM monthly_data
),
final_data AS (
    SELECT
        curr.Year,
        curr.Month_Num,
        CASE curr.Month_Num
            WHEN '04' THEN 'April'
            WHEN '05' THEN 'May'
            WHEN '06' THEN 'June'
            ELSE curr.Month_Num
        END AS Month,
        curr.Total_Cities_Added,
        curr.Running_Cumulative_Total,
        prior.Total_Cities_Added AS Prev_Total_Cities_Added,
        prior.Running_Cumulative_Total AS Prev_Running_Cumulative_Total
    FROM
        running_totals curr
        JOIN running_totals prior ON
            CAST(curr.Year AS INTEGER) - 1 = CAST(prior.Year AS INTEGER) AND
            curr.Month_Num = prior.Month_Num
    WHERE curr.Year > '2021'
)
SELECT
    Year,
    Month,
    Total_Cities_Added,
    Running_Cumulative_Total,
    ROUND(((CAST(Total_Cities_Added AS FLOAT) - Prev_Total_Cities_Added) / Prev_Total_Cities_Added * 100.0), 4) || '%' AS "Year-over-Year Growth Percentage (Monthly)",
    ROUND(((CAST(Running_Cumulative_Total AS FLOAT) - Prev_Running_Cumulative_Total) / Prev_Running_Cumulative_Total * 100.0), 4) || '%' AS "Year-over-Year Growth Percentage (Running Total)"
FROM final_data
ORDER BY CAST(Year AS INTEGER), Month_Num;