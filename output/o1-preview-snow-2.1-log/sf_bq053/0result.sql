WITH species_in_both AS (
    SELECT DISTINCT UPPER(TRIM(ts."species_common_name")) AS species_name, ts."fall_color"
    FROM NEW_YORK.NEW_YORK."TREE_SPECIES" ts
    INNER JOIN NEW_YORK.NEW_YORK."TREE_CENSUS_1995" t1995
        ON UPPER(TRIM(t1995."spc_common")) = UPPER(TRIM(ts."species_common_name"))
        AND t1995."status" != 'Dead'
    INNER JOIN NEW_YORK.NEW_YORK."TREE_CENSUS_2015" t2015
        ON UPPER(TRIM(t2015."spc_common")) = UPPER(TRIM(ts."species_common_name"))
        AND t2015."status" = 'Alive'
)

, counts_1995 AS (
    SELECT s."fall_color", COUNT(*) AS count_1995
    FROM NEW_YORK.NEW_YORK."TREE_CENSUS_1995" t1995
    INNER JOIN species_in_both s
        ON UPPER(TRIM(t1995."spc_common")) = s.species_name
    WHERE t1995."status" != 'Dead'
    GROUP BY s."fall_color"
)

, counts_2015 AS (
    SELECT s."fall_color", COUNT(*) AS count_2015
    FROM NEW_YORK.NEW_YORK."TREE_CENSUS_2015" t2015
    INNER JOIN species_in_both s
        ON UPPER(TRIM(t2015."spc_common")) = s.species_name
    WHERE t2015."status" = 'Alive'
    GROUP BY s."fall_color"
)

SELECT COALESCE(c1995."fall_color", c2015."fall_color") AS "fall_color",
       COALESCE(c1995.count_1995, 0) AS count_1995,
       COALESCE(c2015.count_2015, 0) AS count_2015
FROM counts_1995 c1995
FULL OUTER JOIN counts_2015 c2015
    ON c1995."fall_color" = c2015."fall_color"
ORDER BY "fall_color";