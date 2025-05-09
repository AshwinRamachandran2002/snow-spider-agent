/*  Histogram of common (AF ≥ 0.05) autosomal variants per super‑population
    -----------------------------------------------------------------------
    • Data source  : genomics-public-data.1000_genomes  (US location)
    • Autosomes    : chromosomes ‘1’ … ‘22’  (X, Y, MT excluded)
    • Common       : overall AF (field AF)  ≥ 0.05
    • A sample is counted for a variant if its genotype contains ≥ 1 ALT allele
    • Output per super‑population:
          – population_size        : # samples in that super‑population
          – is_common_variant      : always TRUE (filter already applied)
          – samples_with_variant   : N  (# samples carrying the variant)
          – variant_count          : how many distinct variants are seen in exactly N samples
*/

WITH
-- total number of samples in each super‑population ---------------------------
super_pop_sizes AS (
  SELECT
    Super_Population AS super_population,
    COUNT(DISTINCT Sample) AS population_size
  FROM `genomics-public-data.1000_genomes.sample_info`
  WHERE Super_Population IS NOT NULL
  GROUP BY Super_Population
),

-- one row per (variant, sample, super‑population) where the sample has ≥1 ALT -
variant_sample_sp AS (
  SELECT
    CONCAT(
      v.reference_name, '_',
      CAST(v.start AS STRING), '_',
      v.reference_bases, '_',
      ARRAY_TO_STRING(v.alternate_bases, ',')
    )                           AS variant_id,
    s.Super_Population          AS super_population,
    c.call_set_name             AS sample
  FROM `genomics-public-data.1000_genomes.variants` AS v
  JOIN UNNEST(v.call) AS c
  JOIN `genomics-public-data.1000_genomes.sample_info` AS s
    ON s.Sample = c.call_set_name
  WHERE v.reference_name IN ('1','2','3','4','5','6','7','8','9','10','11',
                             '12','13','14','15','16','17','18','19','20',
                             '21','22')               -- autosomes only
    AND v.AF >= 0.05                                   -- common variants
    -- sample must have at least one ALT allele
    AND (SELECT COUNTIF(gt > 0) FROM UNNEST(c.genotype) AS gt) > 0
    AND s.Super_Population IS NOT NULL
),

-- number of samples (within each super‑population) that carry every variant ---
variant_sp_counts AS (
  SELECT
    super_population,
    variant_id,
    COUNT(DISTINCT sample) AS samples_with_variant
  FROM variant_sample_sp
  GROUP BY super_population, variant_id
)

-- final histogram -------------------------------------------------------------
SELECT
  v.super_population,
  p.population_size,
  TRUE                              AS is_common_variant,
  v.samples_with_variant,           -- N
  COUNT(*) AS variant_count         -- variants seen in exactly N samples
FROM variant_sp_counts AS v
JOIN super_pop_sizes AS p
  ON p.super_population = v.super_population
GROUP BY
  v.super_population,
  p.population_size,
  is_common_variant,
  v.samples_with_variant
ORDER BY
  v.super_population,
  v.samples_with_variant;