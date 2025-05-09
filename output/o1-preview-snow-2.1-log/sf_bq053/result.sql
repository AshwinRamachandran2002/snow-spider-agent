WITH species_alive_2015 AS (
    SELECT DISTINCT LOWER(t2015."spc_latin") AS "spc_latin"
    FROM NEW_YORK.NEW_YORK."TREE_CENSUS_2015" t2015
    WHERE LOWER(t2015."status") = 'alive'
),
counts_1995 AS (
    SELECT s."fall_color", COUNT(*) AS "count_1995"
    FROM NEW_YORK.NEW_YORK."TREE_CENSUS_1995" t1995
    JOIN species_alive_2015 s2015 ON LOWER(t1995."spc_latin") = s2015."spc_latin"
    JOIN NEW_YORK.NEW_YORK."TREE_SPECIES" s ON LOWER(t1995."spc_latin") = LOWER(s."species_scientific_name")
    WHERE LOWER(t1995."status") IN ('good', 'excellent', 'fair', 'poor', 'critical')
    GROUP BY s."fall_color"
),
counts_2015 AS (
    SELECT s."fall_color", COUNT(*) AS "count_2015"
    FROM NEW_YORK.NEW_YORK."TREE_CENSUS_2015" t2015
    JOIN NEW_YORK.NEW_YORK."TREE_SPECIES" s ON LOWER(t2015."spc_latin") = LOWER(s."species_scientific_name")
    WHERE LOWER(t2015."status") = 'alive'
    GROUP BY s."fall_color"
)
SELECT COALESCE(c1995."fall_color", c2015."fall_color") AS "fall_color",
       COALESCE(c1995."count_1995", 0) AS "count_1995",
       COALESCE(c2015."count_2015", 0) AS "count_2015"
FROM counts_1995 c1995
FULL OUTER JOIN counts_2015 c2015 ON c1995."fall_color" = c2015."fall_color"
ORDER BY "fall_color";