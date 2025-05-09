/*  Variants on chr17:41,196,311-41,277,499  
    – positional info, alleles, VT, 1KG AF, HWE-based genotype stats & χ²  */

WITH geno AS (   -- explode sample–level genotypes
    SELECT
        v."reference_name",
        v."start",
        v."end",
        v."reference_bases",
        v."alternate_bases",
        v."VT",
        v."AF"                                     AS "AF_1KG",
        f.value:"genotype"[0]::INT                 AS g1,
        f.value:"genotype"[1]::INT                 AS g2
    FROM "_1000_GENOMES"."_1000_GENOMES"."VARIANTS" v,
         LATERAL FLATTEN(input => v."call") f
    WHERE v."reference_name" = '17'
      AND v."start" BETWEEN 41196311 AND 41277499
),

agg AS (         -- observed genotype counts per variant
    SELECT
        "reference_name",
        "start",
        MIN("end")                                AS "end",
        MIN("reference_bases")                    AS "reference_bases",
        ARRAY_AGG(DISTINCT "alternate_bases")     AS "distinct_alt_bases",
        MIN("VT")                                 AS "VT",
        MIN("AF_1KG")                             AS "AF_1KG",
        COUNT(*)                                  AS "total_genotypes",
        COUNT_IF(g1 = 0 AND g2 = 0)               AS "obs_hom_ref",
        COUNT_IF((g1 = 0 AND g2 = 1) OR (g1 = 1 AND g2 = 0)) AS "obs_het",
        COUNT_IF(g1 = 1 AND g2 = 1)               AS "obs_hom_alt"
    FROM geno
    GROUP BY "reference_name", "start"
),

freq AS (        -- allele frequencies
    SELECT
        *,
        (2*"obs_hom_ref" + "obs_het")::FLOAT / (2*"total_genotypes") AS "ref_freq",
        (2*"obs_hom_alt" + "obs_het")::FLOAT / (2*"total_genotypes") AS "alt_freq"
    FROM agg
),

exp AS (         -- expected genotype counts under HWE
    SELECT
        *,
        "total_genotypes" * POWER("ref_freq",2)      AS "exp_hom_ref",
        2 * "total_genotypes" * "ref_freq" * "alt_freq" AS "exp_het",
        "total_genotypes" * POWER("alt_freq",2)      AS "exp_hom_alt"
    FROM freq
)

SELECT
    "reference_name",
    "start",
    "end",
    "reference_bases",
    "distinct_alt_bases",
    "VT",
    "AF_1KG",
    "total_genotypes",
    "obs_hom_ref",
    "obs_het",
    "obs_hom_alt",
    "exp_hom_ref",
    "exp_het",
    "exp_hom_alt",
    "ref_freq",
    "alt_freq",
    /* χ² goodness-of-fit to Hardy–Weinberg equilibrium */
    (
        POWER("obs_hom_ref" - "exp_hom_ref",2) / NULLIF("exp_hom_ref",0) +
        POWER("obs_het"     - "exp_het"    ,2) / NULLIF("exp_het"    ,0) +
        POWER("obs_hom_alt" - "exp_hom_alt",2) / NULLIF("exp_hom_alt",0)
    )                                              AS "chi_sq"
FROM exp
ORDER BY "start";