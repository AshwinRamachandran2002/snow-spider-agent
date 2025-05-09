/* ---------------------------------------------------------------
   Common autosomal variants (AF ≥ 0.05) – sharing spectrum per
   super-population
   ------------------------------------------------------------- */
WITH
/* 1.  Total number of samples in every super-population */
POP_SIZES AS (
    SELECT
        "Super_Population"            AS SUPER_POP,
        COUNT(*)                      AS POPULATION_SIZE
    FROM "_1000_GENOMES"."_1000_GENOMES"."SAMPLE_INFO"
    WHERE "Super_Population" IS NOT NULL
    GROUP BY "Super_Population"
),

/* 2.  Explode every call for autosomal variants that are common overall */
VARIANT_CALLS AS (
    SELECT
        v."reference_name"                          AS CHR,
        v."start"                                   AS POS,
        v."alternate_bases"::string                 AS ALT,
        v."AF"::float                               AS AF_ALL,
        c.value:"call_set_name"::string             AS SAMPLE_ID,
        c.value:"genotype"[0]::int                  AS G0,
        c.value:"genotype"[1]::int                  AS G1
    FROM "_1000_GENOMES"."_1000_GENOMES"."VARIANTS" v,
         LATERAL FLATTEN ( INPUT => v."call" ) c
    WHERE v."reference_name" NOT IN ('X','Y','MT')   -- autosomes only
      AND v."AF"::float >= 0.05                      -- common variants
),

/* 3.  Keep only those calls where the sample really carries ≥1 alt allele */
SAMPLE_ALT AS (
    SELECT
        CHR, POS, ALT, AF_ALL, SAMPLE_ID
    FROM VARIANT_CALLS
    WHERE (G0 > 0 OR G1 > 0)
),

/* 4.  Map every such sample to its super-population */
VARIANT_SUPER_SAMPLE AS (
    SELECT
        sa.CHR,
        sa.POS,
        sa.ALT,
        sa.AF_ALL,
        si."Super_Population"        AS SUPER_POP,
        sa.SAMPLE_ID
    FROM SAMPLE_ALT sa
    JOIN "_1000_GENOMES"."_1000_GENOMES"."SAMPLE_INFO" si
          ON sa.SAMPLE_ID = si."Sample"
    WHERE si."Super_Population" IS NOT NULL
),

/* 5.  For every (variant, super-population) count how many samples carry it */
VARIANT_SUPER_COUNTS AS (
    SELECT
        SUPER_POP,
        CHR,
        POS,
        ALT,
        COUNT(DISTINCT SAMPLE_ID)    AS SAMPLES_WITH_ALT
    FROM VARIANT_SUPER_SAMPLE
    GROUP BY SUPER_POP, CHR, POS, ALT
),

/* 6.  For every super-population, build the sharing spectrum:
       “How many variants are seen in exactly N samples?” */
SHARING_SPECTRUM AS (
    SELECT
        SUPER_POP,
        SAMPLES_WITH_ALT                     AS SAMPLES_HAVING_VARIANT,
        COUNT(*)                             AS VARIANTS_WITH_THAT_SAMPLE_COUNT
    FROM VARIANT_SUPER_COUNTS
    GROUP BY SUPER_POP, SAMPLES_WITH_ALT
)

/* 7.  Final result */
SELECT
    ss.SUPER_POP                                    AS "SUPER_POPULATION",
    ps.POPULATION_SIZE                              AS "POPULATION_SIZE",
    TRUE                                            AS "IS_COMMON_VARIANT",      -- AF ≥ 0.05 by construction
    ss.SAMPLES_HAVING_VARIANT                       AS "SAMPLES_HAVING_VARIANT",
    ss.VARIANTS_WITH_THAT_SAMPLE_COUNT              AS "VARIANTS_WITH_THAT_SAMPLE_COUNT"
FROM SHARING_SPECTRUM ss
JOIN POP_SIZES   ps ON ss.SUPER_POP = ps.SUPER_POP
ORDER BY ss.SUPER_POP, ss.SAMPLES_HAVING_VARIANT;