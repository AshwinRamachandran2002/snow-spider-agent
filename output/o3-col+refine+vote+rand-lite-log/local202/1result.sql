SELECT COUNT(*) AS "num_states"
FROM (
    -- top 10 states by alien population
    SELECT ad."state"
    FROM (
        SELECT "state"
        FROM "alien_data"
        GROUP BY "state"
        ORDER BY COUNT(*) DESC
        LIMIT 10
    ) AS top
    JOIN "alien_data" ad
      ON ad."state" = top."state"
    GROUP BY ad."state"
    HAVING 
        AVG(ad."age") > 200
        AND SUM(CASE WHEN ad."aggressive" = 0 THEN 1 ELSE 0 END) * 1.0 / COUNT(*) >
            SUM(CASE WHEN ad."aggressive" = 1 THEN 1 ELSE 0 END) * 1.0 / COUNT(*)
) AS qualified_states;