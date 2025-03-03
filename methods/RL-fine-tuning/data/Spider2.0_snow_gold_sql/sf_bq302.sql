WITH monthly_data AS (
    SELECT
        EXTRACT(MONTH FROM TO_TIMESTAMP_NTZ("creation_date" / 1000000)) AS "Month_num",
        CASE EXTRACT(MONTH FROM TO_TIMESTAMP_NTZ("creation_date" / 1000000))
            WHEN 1 THEN 'January'
            WHEN 2 THEN 'February'
            WHEN 3 THEN 'March'
            WHEN 4 THEN 'April'
            WHEN 5 THEN 'May'
            WHEN 6 THEN 'June'
            WHEN 7 THEN 'July'
            WHEN 8 THEN 'August'
            WHEN 9 THEN 'September'
            WHEN 10 THEN 'October'
            WHEN 11 THEN 'November'
            WHEN 12 THEN 'December'
        END AS "Month",
        CASE 
            WHEN "tags" = 'python' 
                OR "tags" LIKE 'python|%' 
                OR "tags" LIKE '%|python|%' 
                OR "tags" LIKE '%|python' 
            THEN 1 
            ELSE 0 
        END AS "is_python"
    FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS
    WHERE EXTRACT(YEAR FROM TO_TIMESTAMP_NTZ("creation_date" / 1000000)) = 2022
)
SELECT
    LPAD(CAST("Month_num" AS VARCHAR), 2, '0') AS "Month_num",
    "Month",
    ROUND(SUM("is_python")::FLOAT / COUNT(*), 4) AS "Proportion"
FROM monthly_data
GROUP BY "Month_num", "Month"
ORDER BY "Month_num";