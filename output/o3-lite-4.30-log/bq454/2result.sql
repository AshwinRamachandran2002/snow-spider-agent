WITH pop_size AS (
  SELECT
    Super_Population AS super_population,
    COUNT(*)         AS population_size
  FROM
    `genomics-public-data.1000_genomes.sample_info`
  WHERE
    Super_Population IS NOT NULL
  GROUP BY
    Super_Population
),
carrier_counts AS (
  SELECT
    v.reference_name,
    v.start,
    si.Super_Population             AS super_population,
    COUNT(DISTINCT c.call_set_name) AS sample_count_sharing_variant
  FROM
    `genomics-public-data.1000_genomes.variants` AS v
  CROSS JOIN
    UNNEST(v.call) AS c
  JOIN
    `genomics-public-data.1000_genomes.sample_info` AS si
  ON
    si.Sample = c.call_set_name
  WHERE
    v.reference_name NOT IN ('X', 'Y', 'MT')       -- autosomal only
    AND v.AF >= 0.05                               -- common variants
    AND EXISTS (SELECT g FROM UNNEST(c.genotype) g -- sample carries alt allele
                WHERE g > 0)
  GROUP BY
    v.reference_name,
    v.start,
    si.Super_Population
)
SELECT
  ps.super_population,
  ps.population_size,
  TRUE                              AS is_common_variant,
  cc.sample_count_sharing_variant,
  COUNT(*)                          AS variant_count
FROM
  carrier_counts AS cc
JOIN
  pop_size       AS ps
ON
  ps.super_population = cc.super_population
GROUP BY
  ps.super_population,
  ps.population_size,
  cc.sample_count_sharing_variant
ORDER BY
  ps.super_population,
  cc.sample_count_sharing_variant;