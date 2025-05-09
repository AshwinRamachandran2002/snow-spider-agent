WITH counts_1995 AS (
  SELECT ts."fall_color", COUNT(*) AS "count_1995"
  FROM NEW_YORK.NEW_YORK.TREE_CENSUS_1995 tc1995
  JOIN NEW_YORK.NEW_YORK.TREE_SPECIES ts
    ON TRIM(UPPER(tc1995."spc_latin")) = TRIM(UPPER(ts."species_scientific_name"))
  WHERE tc1995."status" != 'Dead' AND ts."fall_color" IS NOT NULL
  GROUP BY ts."fall_color"
),
counts_2015 AS (
  SELECT ts."fall_color", COUNT(*) AS "count_2015"
  FROM NEW_YORK.NEW_YORK.TREE_CENSUS_2015 tc2015
  JOIN NEW_YORK.NEW_YORK.TREE_SPECIES ts
    ON TRIM(UPPER(tc2015."spc_latin")) = TRIM(UPPER(ts."species_scientific_name"))
  WHERE tc2015."status" = 'Alive' AND ts."fall_color" IS NOT NULL
  GROUP BY ts."fall_color"
)
SELECT 
  COALESCE(c1995."fall_color", c2015."fall_color") AS "fall_color",
  COALESCE(c1995."count_1995", 0) AS "count_1995",
  COALESCE(c2015."count_2015", 0) AS "count_2015"
FROM counts_1995 c1995
FULL OUTER JOIN counts_2015 c2015
  ON c1995."fall_color" = c2015."fall_color"
ORDER BY "fall_color";