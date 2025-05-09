/*--------------------------------------------------------------------
  Common autosomal variants (AF ≥ 0.05) – distribution of how many
  samples share them inside each 1000 Genomes super‑population
  (Google BigQuery public dataset: genomics-public-data.1000_genomes)
--------------------------------------------------------------------*/
WITH
/* ---------- population size per super‑population ------------------ */
pop_size AS (
  SELECT
    Super_Population AS super_population,
    COUNT(*)         AS pop_size
  FROM `genomics-public-data.1000_genomes.sample_info`
  WHERE Super_Population IS NOT NULL
  GROUP BY Super_Population
),

/* ---------- explode genotype calls & keep autosomes only ---------- */
per_call AS (
  SELECT
    v.reference_name,
    v.start,
    ARRAY_TO_STRING(v.alternate_bases, ',') AS alt_bases,
    s.Super_Population                      AS super_population,

    /* # alt‑allele copies this sample carries at this site (0‑2) */
    (SELECT SUM(IF(allele > 0, 1, 0))
       FROM UNNEST(c.genotype) AS allele)   AS alt_allele_cnt
  FROM `genomics-public-data.1000_genomes.variants` v
  JOIN UNNEST(v.call) AS c
  JOIN `genomics-public-data.1000_genomes.sample_info` s
    ON s.Sample = c.call_set_name
  WHERE v.reference_name NOT IN ('X','Y','MT')        -- autosomes only
),

/* ---------- aggregate per variant within each super‑population ---- */
variant_population_counts AS (
  SELECT
    reference_name,
    start,
    alt_bases,
    super_population,
    COUNTIF(alt_allele_cnt > 0)  AS samples_with_alt,   -- # samples carrying ≥1 alt
    SUM(alt_allele_cnt)          AS alt_allele_copies   -- total alt copies
  FROM per_call
  GROUP BY reference_name, start, alt_bases, super_population
),

/* ---------- keep only common variants (AF ≥ 0.05) ---------------- */
common_variants AS (
  SELECT
    v.super_population,
    ps.pop_size,
    v.samples_with_alt
  FROM variant_population_counts v
  JOIN pop_size ps USING (super_population)
  WHERE (v.alt_allele_copies / (2 * ps.pop_size)) >= 0.05   -- allele frequency
)

/* ---------- final histogram per super‑population ------------------ */
SELECT
  super_population,
  pop_size                                   AS total_population_size,
  TRUE                                       AS is_common,   -- AF ≥ 0.05
  samples_with_alt                           AS num_samples_with_variant,
  COUNT(*)                                   AS variants_shared_by_that_many_samples
FROM common_variants
GROUP BY super_population, pop_size, samples_with_alt
ORDER BY super_population, num_samples_with_variant;