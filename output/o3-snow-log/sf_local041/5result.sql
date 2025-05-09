SELECT 
    ROUND(COUNT_IF("health" = 'Good') * 100.0 / COUNT(*), 4) AS "percentage_good_health_bronx"
FROM MODERN_DATA.MODERN_DATA.TREES
WHERE "boroname" = 'Bronx';