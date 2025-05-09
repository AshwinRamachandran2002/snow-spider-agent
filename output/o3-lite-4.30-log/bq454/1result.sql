WITH pop_size AS (
  -- size of each super‑population
  SELECT
    super_population,
    COUNT(*) AS population_size
  FROM `bigquery-public-data.human_genome_variants.1000_genomes_sample_info`
  GROUP BY super_population
),
per_variant AS (
  -- number of distinct carriers of a common autosomal variant within each super‑population
  SELECT
    v.reference_name,
    v.start_position,
    s.super_population,
    COUNT(DISTINCT c.name) AS sample_count_sharing_variant
  FROM `bigquery-public-data.human_genome_variants.1000_genomes_phase_3_variants_20150220` AS v
  JOIN UNNEST(v.alternate_bases) AS ab          -- to reach AF
  JOIN UNNEST(v.call)            AS c           -- per‑sample calls
  JOIN `bigquery-public-data.human_genome_variants.1000_genomes_sample_info` AS s
    ON s.sample = c.name
  WHERE SAFE_CAST(v.reference_name AS INT64) BETWEEN 1 AND 22      -- autosomes only
    AND ab.AF >= 0.05                                              -- common variants
    AND (SELECT COUNTIF(allele > 0) FROM UNNEST(c.genotype) allele) > 0  -- carrier of ALT
  GROUP BY v.reference_name, v.start_position, s.super_population
)
SELECT
  pv.super_population,
  ps.population_size,
  TRUE AS is_common_variant,                   -- AF filter guarantees common status
  pv.sample_count_sharing_variant,
  COUNT(*) AS variant_count
FROM per_variant AS pv
JOIN pop_size    AS ps USING (super_population)
GROUP BY
  pv.super_population,
  ps.population_size,
  is_common_variant,
  pv.sample_count_sharing_variant
ORDER BY
  pv.super_population,
  pv.sample_count_sharing_variant;