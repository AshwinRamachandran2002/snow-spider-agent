/*  Variant-by-variant Hardy-Weinberg test – Chr-17 : 41 196 311-41 277 499  */

WITH interval_variants AS (          -- all variants inside the requested window
    SELECT *
    FROM _1000_GENOMES._1000_GENOMES."VARIANTS"
    WHERE "reference_name" = '17'
      AND "start" BETWEEN 41196311 AND 41277499
),

/* ------------------------------------------------------------------------
   Count usable genotypes per variant (ignore missing ‑1 / ‑1 calls)
----------------------------------------------------------------------------*/
geno AS (
    SELECT
        v."reference_name",
        v."start",
        v."end",

        /* observed genotype tallies */
        SUM( CASE WHEN gt0 = 0 AND gt1 = 0                       THEN 1 ELSE 0 END ) AS hom_ref,
        SUM( CASE WHEN gt0 = gt1 AND gt0 > 0                     THEN 1 ELSE 0 END ) AS hom_alt,
        SUM( CASE WHEN (gt0 = 0 AND gt1 > 0) 
                    OR (gt0 > 0 AND gt1 = 0) 
                    OR (gt0 <> gt1 AND gt0 > 0 AND gt1 > 0)      THEN 1 ELSE 0 END ) AS het,

        COUNT(*)                                                 AS total_genotypes
    FROM interval_variants v,
         LATERAL FLATTEN( INPUT => v."call" ) c,
         LATERAL (
             SELECT
                 c.value:"genotype"[0]::INT AS gt0,
                 c.value:"genotype"[1]::INT AS gt1
         ) g
    WHERE gt0 >= 0             -- keep only non-missing genotypes
      AND gt1 >= 0
    GROUP BY v."reference_name", v."start", v."end"
),

/* ------------------------------------------------------------------------
   Observed ALT-allele frequency
----------------------------------------------------------------------------*/
freqs AS (
    SELECT
        g.*,
        ( (2*g.hom_alt + g.het)::FLOAT ) / (2*g.total_genotypes) AS alt_af_obs
    FROM geno g
),

/* ------------------------------------------------------------------------
   Hardy-Weinberg expected counts
----------------------------------------------------------------------------*/
expect AS (
    SELECT
        f.*,
        /* Expected genotype numbers under HWE */
        POWER(1 - f.alt_af_obs , 2)   * f.total_genotypes         AS exp_hom_ref,
        2 * f.alt_af_obs * (1-f.alt_af_obs) * f.total_genotypes   AS exp_het,
        POWER(  f.alt_af_obs , 2)     * f.total_genotypes         AS exp_hom_alt
    FROM freqs f
),

/* ------------------------------------------------------------------------
   Pearson χ² statistic (df = 1 for bi-allelic)
----------------------------------------------------------------------------*/
chisq AS (
    SELECT
        e.*,
        /* avoid division-by-zero with NULLIF */
        ( POWER(e.hom_ref - e.exp_hom_ref , 2) / NULLIF(e.exp_hom_ref , 0)
        + POWER(e.het      - e.exp_het     , 2) / NULLIF(e.exp_het     , 0)
        + POWER(e.hom_alt  - e.exp_hom_alt , 2) / NULLIF(e.exp_hom_alt , 0)
        )                                                        AS chi_square
    FROM expect e
)

/* ------------------------------------------------------------------------
   Final report – one row per (variant × alternate allele)
----------------------------------------------------------------------------*/
SELECT
    v."reference_name",
    v."start",
    v."end",
    v."reference_bases",
    alt.value::STRING                                    AS alt_allele,
    v."VT",
    v."SVTYPE",

    /* observed genotype counts */
    c.hom_ref,
    c.het,
    c.hom_alt,
    c.total_genotypes,

    /* observed and 1KG-supplied allele frequencies */
    ROUND(c.alt_af_obs , 6)                              AS ALT_AF_OBS,
    v."AF"       AS AF_1KG_OVERALL,
    v."AFR_AF",
    v."EUR_AF",
    v."ASN_AF",
    v."AMR_AF",

    /* expected genotype counts & χ² */
    ROUND(c.exp_hom_ref , 4)                             AS EXP_HOM_REF,
    ROUND(c.exp_het     , 4)                             AS EXP_HET,
    ROUND(c.exp_hom_alt , 4)                             AS EXP_HOM_ALT,
    ROUND(c.chi_square  , 4)                             AS CHI_SQ_HWE

FROM interval_variants v
JOIN chisq           c
  ON v."reference_name" = c."reference_name"
 AND v."start"         = c."start"
 AND v."end"           = c."end"
,    LATERAL FLATTEN( INPUT => v."alternate_bases" ) alt
ORDER BY v."start", alt_allele;