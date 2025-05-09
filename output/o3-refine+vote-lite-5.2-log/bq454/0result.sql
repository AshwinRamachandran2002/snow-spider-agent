/* -----------------------------------------------------------------------
   Histogram of COMMON (allele‑frequency ≥ 0.05) AUTOSOMAL variants
   in every super‑population of the 1000 Genomes Project

   Public BigQuery dataset used:  genomics-public-data.1000_genomes
   --------------------------------------------------------------------- */

WITH
/* 1.  Map samples to super‑populations and obtain population size ----- */
sample_pops AS (
  SELECT
    Sample              AS sample_id,
    Super_Population    AS super_pop
  FROM `genomics-public-data.1000_genomes.sample_info`
  WHERE Super_Population IS NOT NULL
),
pop_size AS (
  SELECT
    super_pop,
    COUNT(*)            AS population_size
  FROM sample_pops
  GROUP BY super_pop
),

/* 2.  Expand each variant’s call array → one row per (variant, sample) */
calls_expanded AS (
  SELECT
    v.reference_name,
    v.start,
    v.reference_bases,
    v.alternate_bases[SAFE_OFFSET(0)]       AS alt_base,
    c.call_set_name                         AS sample_id,
    /* count non‑reference alleles */
    (SELECT SUM(IF(g > 0, 1, 0))
       FROM UNNEST(c.genotype) AS g)        AS alt_allele_cnt,
    /* count alleles that were actually called (exclude ‑1) */
    (SELECT COUNTIF(g >= 0)
       FROM UNNEST(c.genotype) AS g)        AS total_allele_cnt
  FROM `genomics-public-data.1000_genomes.variants` AS v
  CROSS JOIN UNNEST(v.call) AS c
  WHERE v.reference_name NOT IN ('X','Y','MT')      -- AUTOSOMES ONLY
),

/* 3.  Attach super‑population information to every call -------------- */
calls_with_pop AS (
  SELECT
    ce.*,
    sp.super_pop
  FROM calls_expanded AS ce
  JOIN sample_pops    AS sp
    ON ce.sample_id = sp.sample_id
),

/* 4.  Aggregate to one row per (variant, super‑population) ----------- */
variant_by_pop AS (
  SELECT
    reference_name,
    start,
    reference_bases,
    alt_base,
    super_pop,
    COUNTIF(alt_allele_cnt > 0)             AS samples_with_alt,
    SUM(alt_allele_cnt)                     AS alt_alleles,
    SUM(total_allele_cnt)                   AS total_alleles
  FROM calls_with_pop
  GROUP BY reference_name, start, reference_bases,
           alt_base, super_pop
),

/* 5.  Keep only COMMON variants (AF ≥ 0.05 in that super‑pop) -------- */
common_variant_by_pop AS (
  SELECT
    *,
    SAFE_DIVIDE(alt_alleles, total_alleles) AS allele_frequency
  FROM variant_by_pop
  WHERE total_alleles > 0
    AND SAFE_DIVIDE(alt_alleles, total_alleles) >= 0.05
),

/* 6.  Build histogram: for each N carriers, how many variants? ------- */
histogram AS (
  SELECT
    cvp.super_pop,
    ps.population_size,
    TRUE                                     AS is_common_variant,
    cvp.samples_with_alt,                    -- number of carriers
    COUNT(*)                                 AS variants_count
  FROM common_variant_by_pop AS cvp
  JOIN pop_size              AS ps
    ON cvp.super_pop = ps.super_pop
  GROUP BY
    cvp.super_pop,
    ps.population_size,
    is_common_variant,
    cvp.samples_with_alt
)

/* 7.  Final ordered result ------------------------------------------- */
SELECT
  super_pop,
  population_size,
  is_common_variant,
  samples_with_alt,
  variants_count
FROM histogram
ORDER BY
  super_pop,
  samples_with_alt;