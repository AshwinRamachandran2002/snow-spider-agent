/*  Variant-level Hardy-Weinberg statistics together with annotation & 1KG
    allele-frequency columns for chr17 : 41 196 311–41 277 499             */

WITH geno AS (      -------------------------------------------------------
  /* 1.  Flatten per-sample genotypes and tally observed counts            */
  SELECT
      g0."reference_name",
      g0."start",
      g0."end",
      COUNT(*)                                                   AS total_gts,
      SUM(CASE WHEN g0.a1 = 0 AND g0.a2 = 0 THEN 1 END)         AS obs_hom_ref,
      SUM(CASE WHEN (g0.a1 = 0 AND g0.a2 = 1)
             OR (g0.a1 = 1 AND g0.a2 = 0) THEN 1 END)           AS obs_het,
      SUM(CASE WHEN g0.a1 = 1 AND g0.a2 = 1 THEN 1 END)         AS obs_hom_alt
  FROM (
      SELECT
          v."reference_name",
          v."start",
          v."end",
          c.value:"genotype"[0]::INT AS a1,
          c.value:"genotype"[1]::INT AS a2
      FROM "_1000_GENOMES"."_1000_GENOMES"."VARIANTS" v,
           LATERAL FLATTEN(input => v."call") c
      WHERE v."reference_name" = '17'
        AND v."start" BETWEEN 41196311 AND 41277499
  ) g0
  GROUP BY g0."reference_name", g0."start", g0."end"
), geno2 AS (       -------------------------------------------------------
  /* 2.  Calculate allele-frequency, expected counts & χ² statistic        */
  SELECT
      g.*,
      /* alternate-allele frequency (p) */
      (g.obs_het + 2*g.obs_hom_alt)::FLOAT / (2*g.total_gts)                   AS p_alt,

      /* expected genotype counts under HWE                                  */
      POWER(1 - ((g.obs_het + 2*g.obs_hom_alt)::FLOAT / (2*g.total_gts)),2)
        * g.total_gts                                                          AS exp_hom_ref,

      2 * ((g.obs_het + 2*g.obs_hom_alt)::FLOAT / (2*g.total_gts))
        * (1 - ((g.obs_het + 2*g.obs_hom_alt)::FLOAT / (2*g.total_gts)))
        * g.total_gts                                                          AS exp_het,

      POWER(((g.obs_het + 2*g.obs_hom_alt)::FLOAT / (2*g.total_gts)),2)
        * g.total_gts                                                          AS exp_hom_alt,

      /* Pearson χ² statistic                                                */
      (
        POWER( g.obs_hom_ref -
               ( POWER(1 - ((g.obs_het + 2*g.obs_hom_alt)::FLOAT /
                            (2*g.total_gts)),2) * g.total_gts ), 2)
        / NULLIF(
            POWER(1 - ((g.obs_het + 2*g.obs_hom_alt)::FLOAT / (2*g.total_gts)),2)
            * g.total_gts ,0)
      ) +
      (
        POWER( g.obs_het -
               ( 2*((g.obs_het + 2*g.obs_hom_alt)::FLOAT / (2*g.total_gts)) *
                 (1 - ((g.obs_het + 2*g.obs_hom_alt)::FLOAT / (2*g.total_gts)))
                 * g.total_gts ), 2)
        / NULLIF(
            2*((g.obs_het + 2*g.obs_hom_alt)::FLOAT / (2*g.total_gts)) *
            (1 - ((g.obs_het + 2*g.obs_hom_alt)::FLOAT / (2*g.total_gts))) *
            g.total_gts ,0)
      ) +
      (
        POWER( g.obs_hom_alt -
               ( POWER(((g.obs_het + 2*g.obs_hom_alt)::FLOAT / (2*g.total_gts)),2)
                 * g.total_gts), 2)
        / NULLIF(
            POWER(((g.obs_het + 2*g.obs_hom_alt)::FLOAT / (2*g.total_gts)),2)
            * g.total_gts ,0)
      )                                                                      AS chisq_hwe
  FROM geno g
), alt AS (        ----------------------------------------------------------
  /* 3.  Collect distinct alternate bases into a comma-separated list       */
  SELECT
      v."reference_name",
      v."start",
      v."end",
      LISTAGG(DISTINCT ab.value::STRING, ',')
        WITHIN GROUP (ORDER BY ab.value::STRING)                             AS alternate_bases
  FROM "_1000_GENOMES"."_1000_GENOMES"."VARIANTS" v,
       LATERAL FLATTEN(input => v."alternate_bases") ab
  WHERE v."reference_name" = '17'
    AND v."start" BETWEEN 41196311 AND 41277499
  GROUP BY v."reference_name", v."start", v."end"
)                   ----------------------------------------------------------
SELECT
    v."reference_name",
    v."start",
    v."end",
    v."reference_bases",
    a.alternate_bases,
    v."VT"                                            AS variant_type,

    /* Observed genotype counts */
    g.total_gts,
    g.obs_hom_ref,
    g.obs_het,
    g.obs_hom_alt,

    /* Expected genotype counts (rounded) */
    ROUND(g.exp_hom_ref, 2)                           AS exp_hom_ref,
    ROUND(g.exp_het, 2)                               AS exp_het,
    ROUND(g.exp_hom_alt, 2)                           AS exp_hom_alt,

    /* χ² statistic & allele frequency */
    ROUND(g.chisq_hwe, 4)                             AS chisq_hwe,
    ROUND(g.p_alt,     4)                             AS calc_alt_freq,

    /* Catalogue / 1KG allele frequencies */
    v."AF"                                            AS cat_alt_freq,
    v."AFR_AF",
    v."AMR_AF",
    v."EUR_AF",
    v."ASN_AF"

FROM "_1000_GENOMES"."_1000_GENOMES"."VARIANTS" v
JOIN geno2 g
      ON v."reference_name" = g."reference_name"
     AND v."start"           = g."start"
     AND v."end"             = g."end"
JOIN alt  a
      ON v."reference_name" = a."reference_name"
     AND v."start"          = a."start"
     AND v."end"            = a."end"
WHERE v."reference_name" = '17'
  AND v."start" BETWEEN 41196311 AND 41277499
ORDER BY v."start";