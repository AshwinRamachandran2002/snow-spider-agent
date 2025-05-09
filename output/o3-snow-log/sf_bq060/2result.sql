SELECT
    c."country_name",
    b."net_migration"
FROM
    CENSUS_BUREAU_INTERNATIONAL.CENSUS_BUREAU_INTERNATIONAL."BIRTH_DEATH_GROWTH_RATES" AS b
JOIN
    CENSUS_BUREAU_INTERNATIONAL.CENSUS_BUREAU_INTERNATIONAL."COUNTRY_NAMES_AREA"          AS c
      ON b."country_code" = c."country_code"
WHERE
    b."year" = 2017
    AND c."country_area" > 500
    AND b."net_migration" IS NOT NULL
ORDER BY
    b."net_migration" DESC NULLS LAST
LIMIT 3;