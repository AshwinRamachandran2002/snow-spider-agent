WITH
/* living trees in the 1995 census */
c1995 AS (
    SELECT 
        UPPER("spc_latin") AS species,
        COUNT(*)            AS cnt_1995
    FROM NEW_YORK.NEW_YORK.TREE_CENSUS_1995
    WHERE 
        "spc_latin" IS NOT NULL
        AND "status" IS NOT NULL
        /* treat any record whose status contains DEAD / STUMP / PLANTING as not-living */
        AND UPPER("status") NOT LIKE '%DEAD%'
        AND UPPER("status") NOT LIKE '%STUMP%'
        AND UPPER("status") NOT LIKE '%PLANTING%'
    GROUP BY species
),

/* living trees in the 2015 census */
c2015 AS (
    SELECT
        UPPER("spc_latin") AS species,
        COUNT(*)           AS cnt_2015
    FROM NEW_YORK.NEW_YORK.TREE_CENSUS_2015
    WHERE 
        "spc_latin" IS NOT NULL
        AND UPPER("status") = 'ALIVE'
    GROUP BY species
),

/* per-species change from 1995 → 2015 */
diff AS (
    SELECT
        COALESCE(c19.species, c15.species)                           AS species,
        COALESCE(c15.cnt_2015, 0) - COALESCE(c19.cnt_1995, 0)        AS change
    FROM c1995 c19
    FULL OUTER JOIN c2015 c15
        ON c19.species = c15.species
),

/* scientific name → fall color lookup */
species_fc AS (
    SELECT 
        UPPER("species_scientific_name") AS species,
        "fall_color"
    FROM NEW_YORK.NEW_YORK.TREE_SPECIES
)

/* sum the per-species changes by fall color */
SELECT
    sf."fall_color",
    SUM(d.change) AS total_change
FROM diff            d
JOIN species_fc      sf
  ON d.species = sf.species
GROUP BY sf."fall_color"
ORDER BY total_change DESC NULLS LAST;