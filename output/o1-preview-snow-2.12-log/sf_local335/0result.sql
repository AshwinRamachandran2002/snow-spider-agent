SELECT 
    c."name" AS "Constructor", 
    COUNT(*) AS "Number_of_Seasons_With_Fewest_Points"
FROM (
    SELECT 
        ra."year", 
        r."constructor_id", 
        SUM(r."points") AS "total_constructor_points",
        RANK() OVER (PARTITION BY ra."year" ORDER BY SUM(r."points") ASC) AS "constructor_rank"
    FROM 
        "F1"."F1"."RESULTS" r
    JOIN 
        "F1"."F1"."RACES" ra ON r."race_id" = ra."race_id"
    WHERE 
        ra."year" >= 2001
    GROUP BY 
        ra."year", r."constructor_id"
) t
JOIN "F1"."F1"."CONSTRUCTORS" c ON t."constructor_id" = c."constructor_id"
WHERE t."constructor_rank" = 1
GROUP BY c."name"
ORDER BY "Number_of_Seasons_With_Fewest_Points" DESC NULLS LAST
LIMIT 5;