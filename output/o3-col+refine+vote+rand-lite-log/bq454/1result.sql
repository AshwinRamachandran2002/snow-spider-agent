-- Distribution of common (AF ≥ 0.05) autosomal variants per super-population
WITH pop_size AS (           -- number of individuals per super-population
  SELECT
    Super_Population AS super_pop,
    COUNT(*)         AS pop_size
  FROM `genomics-public-data.1000_genomes.sample_info`
  WHERE Super_Population IS NOT NULL
  GROUP BY super_pop
),
per_variant AS (             -- carrier count of each autosomal variant
  SELECT
    si.Super_Population AS super_pop,
    v.reference_name,
    v.start,
    COUNTIF(
      EXISTS (SELECT g FROM UNNEST(c.genotype) AS g WHERE g > 0)   -- carries alt
    )                        AS carrier_cnt
  FROM `genomics-public-data.1000_genomes.variants` AS v
  CROSS JOIN UNNEST(v.call)  AS c
  JOIN `genomics-public-data.1000_genomes.sample_info` AS si
    ON si.Sample = c.call_set_name
  WHERE v.reference_name NOT IN ('X','Y','MT')                     -- autosomes
  GROUP BY super_pop, v.reference_name, v.start
),
with_freq AS (               -- compute allele frequency within each pop
  SELECT
    pv.super_pop,
    pv.carrier_cnt,
    pv.carrier_cnt / (2 * ps.pop_size) AS allele_freq,             -- 2 alleles/sample
    ps.pop_size
  FROM per_variant AS pv
  JOIN pop_size   AS ps
    ON pv.super_pop = ps.super_pop
)
SELECT
  super_pop              AS super_population,
  pop_size               AS population_size,
  carrier_cnt            AS samples_with_variant,
  TRUE                   AS is_common_variant,                     -- AF ≥ 0.05
  COUNT(*)               AS variants_count
FROM with_freq
WHERE allele_freq >= 0.05
GROUP BY super_pop, pop_size, carrier_cnt
ORDER BY super_pop, carrier_cnt;