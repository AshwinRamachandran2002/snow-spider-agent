WITH pop_sizes AS (
  /* size of each super‑population */
  SELECT
    Super_Population AS super_population,
    COUNT(*)         AS population_size
  FROM `genomics-public-data.1000_genomes.sample_info`
  GROUP BY super_population
),
per_variant AS (
  /* for every autosomal variant, compute:
     – number of samples carrying ≥1 ALT allele
     – total number of ALT alleles (for AF calculation) */
  SELECT
    v.reference_name,
    v.start,
    v.`end`,
    s.Super_Population                    AS super_population,
    COUNT(DISTINCT c.call_set_name)       AS sample_count_sharing_variant,
    SUM((
      SELECT COUNTIF(g > 0)
      FROM UNNEST(c.genotype) AS g        /* counts ALT alleles per call */
    ))                                    AS alt_allele_count
  FROM `genomics-public-data.1000_genomes.variants` AS v
  CROSS JOIN UNNEST(v.call) AS c
  JOIN `genomics-public-data.1000_genomes.sample_info` AS s
    ON s.Sample = c.call_set_name
  WHERE
    v.reference_name NOT IN ('X','Y','MT')   /* autosomes only */
    AND EXISTS (
      SELECT 1 FROM UNNEST(c.genotype) AS g WHERE g > 0   /* sample has ALT */
    )
  GROUP BY v.reference_name, v.start, v.`end`, super_population
),
flagged AS (
  /* retain variants common (AF ≥ 0.05) within each super‑population */
  SELECT
    pv.super_population,
    ps.population_size,
    pv.sample_count_sharing_variant,
    TRUE AS is_common_variant
  FROM per_variant AS pv
  JOIN pop_sizes  AS ps
    ON ps.super_population = pv.super_population
  WHERE
    pv.alt_allele_count / (2 * ps.population_size) >= 0.05
)
SELECT
  super_population,
  population_size,
  is_common_variant,
  sample_count_sharing_variant,
  COUNT(*) AS variant_count
FROM flagged
GROUP BY
  super_population,
  population_size,
  is_common_variant,
  sample_count_sharing_variant
ORDER BY
  super_population,
  sample_count_sharing_variant;