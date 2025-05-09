/*  Variant-level Hardy-Weinberg statistics plus 1KG allele frequencies
    for chr17 : 41 196 311-41 277 499                                          */

WITH genos AS (        -- explode every genotype for variants in the window
  SELECT
      v."start"                       AS pos_start,
      v."end"                         AS pos_end,
      CASE
          WHEN g.value:"genotype"[0]::INT = 0
           AND g.value:"genotype"[1]::INT = 0 THEN 'hom_ref'
          WHEN g.value:"genotype"[0]::INT = 1
           AND g.value:"genotype"[1]::INT = 1 THEN 'hom_alt'
          ELSE 'het'
      END                              AS gclass,
      (g.value:"genotype"[0]::INT + 
       g.value:"genotype"[1]::INT)     AS alt_sum
  FROM "_1000_GENOMES"."_1000_GENOMES"."VARIANTS"  v,
       LATERAL FLATTEN (INPUT => v."call")         g
  WHERE v."reference_name" = '17'
    AND v."start" BETWEEN 41196311 AND 41277499
),
obs AS (          -- observed genotype counts & sample size
  SELECT
      pos_start,
      pos_end,
      COUNT_IF(gclass = 'hom_ref')  AS o_rr,
      COUNT_IF(gclass = 'het')      AS o_ra,
      COUNT_IF(gclass = 'hom_alt')  AS o_aa,
      COUNT(*)                      AS n
  FROM genos
  GROUP BY pos_start, pos_end
),
allele AS (       -- allele counts / total alleles
  SELECT
      pos_start,
      pos_end,
      SUM(alt_sum)         AS ac,
      COUNT(*) * 2         AS an
  FROM genos
  GROUP BY pos_start, pos_end
),
stats AS (        -- allele freqs
  SELECT
      o.pos_start,
      o.pos_end,
      o.n,
      o.o_rr, o.o_ra, o.o_aa,
      a.ac,
      a.an,
      a.ac::FLOAT / a.an              AS p_alt,
      1 - a.ac::FLOAT / a.an          AS p_ref
  FROM obs    o
  JOIN allele a USING (pos_start, pos_end)
),
chi AS (          -- expected counts & χ²
  SELECT
      pos_start,
      pos_end,
      n,
      o_rr, o_ra, o_aa,
      ROUND(n * POWER(p_ref,2)      ,2)              AS e_rr,
      ROUND(n * 2*p_ref*p_alt        ,2)             AS e_ra,
      ROUND(n * POWER(p_alt,2)      ,2)              AS e_aa,
      ROUND(
           NVL(POWER(o_rr - n*POWER(p_ref,2),2) /
               NULLIF(n*POWER(p_ref,2),0),0) +
           NVL(POWER(o_ra - n*2*p_ref*p_alt,2) /
               NULLIF(n*2*p_ref*p_alt,0),0) +
           NVL(POWER(o_aa - n*POWER(p_alt,2),2) /
               NULLIF(n*POWER(p_alt,2),0),0)
           ,4)                                       AS chi_sq,
      ROUND(p_alt,4)                                 AS calc_alt_af
  FROM stats
)
SELECT
    v."reference_name",
    v."start",
    v."end",
    v."reference_bases",
    ARRAY_TO_STRING(v."alternate_bases",',')         AS "alt_bases",
    v."VT"                                           AS "variant_type",
    c.n                                              AS "total_genotypes",
    c.o_rr                                           AS "obs_hom_ref",
    c.o_ra                                           AS "obs_het",
    c.o_aa                                           AS "obs_hom_alt",
    c.e_rr                                           AS "exp_hom_ref",
    c.e_ra                                           AS "exp_het",
    c.e_aa                                           AS "exp_hom_alt",
    c.chi_sq                                         AS "chi_squared",
    v."AFR_AF"                                       AS "afr_af",
    v."EUR_AF"                                       AS "eur_af",
    v."AMR_AF"                                       AS "amr_af",
    v."ASN_AF"                                       AS "asn_af",
    c.calc_alt_af                                    AS "calc_alt_af"
FROM "_1000_GENOMES"."_1000_GENOMES"."VARIANTS"  v
JOIN chi c
  ON v."start" = c.pos_start
 AND v."end"   = c.pos_end
WHERE v."reference_name" = '17'
  AND v."start" BETWEEN 41196311 AND 41277499
ORDER BY v."start";