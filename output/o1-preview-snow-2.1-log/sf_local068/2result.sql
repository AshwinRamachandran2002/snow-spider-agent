WITH monthly_totals AS (
    SELECT
        TO_NUMBER(SUBSTR("insert_date",1,4)) AS "Year",
        TO_NUMBER(SUBSTR("insert_date",6,2)) AS "Month_Number",
        CASE SUBSTR("insert_date",6,2)
            WHEN '04' THEN 'April'
            WHEN '05' THEN 'May'
            WHEN '06' THEN 'June'
        END AS "Month",
        COUNT(*) AS "Total_cities_added"
    FROM
        CITY_LEGISLATION.CITY_LEGISLATION.CITIES
    WHERE
        SUBSTR("insert_date",6,2) IN ('04', '05', '06')
        AND SUBSTR("insert_date",1,4) IN ('2021','2022','2023')
    GROUP BY
        "Year", "Month_Number", "Month"
),
monthly_with_cumulative AS (
    SELECT
        "Year",
        "Month",
        "Month_Number",
        "Total_cities_added",
        SUM("Total_cities_added") OVER (PARTITION BY "Year" ORDER BY "Month_Number") AS "Running_cumulative_total"
    FROM
        monthly_totals
)
SELECT
    curr."Year",
    curr."Month",
    curr."Total_cities_added",
    curr."Running_cumulative_total",
    ROUND(((curr."Total_cities_added" - prev."Total_cities_added") / prev."Total_cities_added") * 100, 4) AS "YoY_monthly_growth",
    ROUND(((curr."Running_cumulative_total" - prev."Running_cumulative_total") / prev."Running_cumulative_total") * 100, 4) AS "YoY_running_total_growth"
FROM
    monthly_with_cumulative curr
JOIN
    monthly_with_cumulative prev
    ON curr."Year" = prev."Year" + 1 AND curr."Month_Number" = prev."Month_Number"
WHERE
    curr."Year" IN (2022, 2023)
ORDER BY
    curr."Year", curr."Month_Number";