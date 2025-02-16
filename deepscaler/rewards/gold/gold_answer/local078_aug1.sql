-- Task: Identify the top 10 interest categories based on their highest composition values across all months. For each category, display the interest name and the highest composition value.

SELECT
    t2.interest_name,
    MAX(t1.composition) AS highest_composition
FROM 
    interest_metrics AS t1
JOIN 
    interest_map AS t2
ON 
    t1.interest_id = t2.id
WHERE 
    t1.month_year IS NOT NULL
GROUP BY
    t2.interest_name
ORDER BY
    highest_composition DESC
LIMIT 10;