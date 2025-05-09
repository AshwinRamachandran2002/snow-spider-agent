WITH
-- 1995 census : trees that are NOT marked as dead or stump
c1995 AS (
    SELECT
        UPPER(TRIM("spc_latin"))           AS species,
        COUNT(*)                           AS cnt_1995
    FROM NEW_YORK.NEW_YORK.TREE_CENSUS_1995
    WHERE UPPER(TRIM("status")) NOT IN ('DEAD','STUMP')
          AND "spc_latin" IS NOT NULL
    GROUP BY 1
),

-- 2015 census : trees whose status is explicitly Alive
c2015 AS (
    SELECT
        UPPER(TRIM("spc_latin"))           AS species,
        COUNT(*)                           AS cnt_2015
    FROM NEW_YORK.NEW_YORK.TREE_CENSUS_2015
    WHERE UPPER(TRIM("status")) = 'ALIVE'
          AND "spc_latin" IS NOT NULL
    GROUP BY 1
),

-- species reference with fall-color information
species_info AS (
    SELECT
        UPPER(TRIM("species_scientific_name")) AS species,
        "fall_color"
    FROM NEW_YORK.NEW_YORK.TREE_SPECIES
    WHERE "fall_color" IS NOT NULL
)

-- combine, compute per-species change, then aggregate by fall color
SELECT
    COALESCE(si."fall_color", 'Unknown')                           AS "fall_color",
    SUM( COALESCE(c15.cnt_2015,0) - COALESCE(c95.cnt_1995,0) )     AS "total_change"
FROM species_info            AS si
LEFT JOIN c1995              AS c95  ON si.species = c95.species
LEFT JOIN c2015              AS c15  ON si.species = c15.species
GROUP BY COALESCE(si."fall_color", 'Unknown')
ORDER BY "total_change" DESC NULLS LAST;