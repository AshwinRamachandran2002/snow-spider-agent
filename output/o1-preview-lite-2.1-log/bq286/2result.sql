SELECT 
    wy.name
FROM 
    (
        SELECT name, SUM(number) AS wy_number
        FROM `bigquery-public-data.usa_names.usa_1910_current`
        WHERE state = 'WY' AND gender = 'F' AND year = 2021
        GROUP BY name
    ) AS wy
JOIN 
    (
        SELECT name, SUM(number) AS total_number
        FROM `bigquery-public-data.usa_names.usa_1910_current`
        WHERE gender = 'F' AND year = 2021
        GROUP BY name
    ) AS total
ON wy.name = total.name
ORDER BY (wy.wy_number / total.total_number) DESC
LIMIT 1;