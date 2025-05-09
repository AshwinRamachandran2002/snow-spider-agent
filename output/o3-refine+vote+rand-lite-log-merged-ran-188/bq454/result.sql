/* -----------------------------------------------------------
   Common autosomal variants (AF ≥ 0.05) – distribution by the
   number of carriers inside each 1000 Genomes super-population
   ----------------------------------------------------------- */
WITH samples AS (  -- map sample → super-population
  SELECT
    Sample AS sample_id,
    Super_Population
  FROM `genomics-public-data.1000_genomes.sample_info`
  WHERE Super_Population IS NOT NULL
),
pop_sizes AS (     -- population sizes
  SELECT
    Super_Population,
    COUNT(*) AS pop_size
  FROM samples
  GROUP BY Super_Population
),
variant_calls AS ( -- explode calls, keep autosomes (chr 1-22)
  SELECT
    v.reference_name,
    v.start,
    v.alternate_bases,
    c.call_set_name AS sample_id,
    c.genotype
  FROM `genomics-public-data.1000_genomes.variants` AS v
  CROSS JOIN UNNEST(v.call) AS c
  WHERE v.reference_name NOT IN ('X','Y','MT')      -- autosomes only
),
calls_with_pop AS (  -- attach super-population information
  SELECT
    vc.reference_name,
    vc.start,
    vc.alternate_bases,
    s.Super_Population,
    vc.sample_id,
    vc.genotype
  FROM variant_calls AS vc
  JOIN samples       AS s
    ON vc.sample_id = s.sample_id
),
per_variant_pop AS ( -- per-variant stats within each super-pop
  SELECT
    reference_name,
    start,
    alternate_bases,
    Super_Population,
    COUNTIF( EXISTS (SELECT 1 FROM UNNEST(genotype) AS g WHERE g > 0) )
                                        AS samples_with_alt,
    SUM( (SELECT SUM(CASE WHEN g > 0 THEN 1 ELSE 0 END)
          FROM UNNEST(genotype) AS g) ) AS alt_allele_cnt
  FROM calls_with_pop
  GROUP BY reference_name, start, alternate_bases, Super_Population
),
common_variants AS ( -- retain variants with AF ≥ 0.05 in each pop
  SELECT
    pvp.*,
    ps.pop_size,
    SAFE_DIVIDE(alt_allele_cnt, 2 * ps.pop_size) AS allele_freq
  FROM per_variant_pop AS pvp
  JOIN pop_sizes        AS ps
    USING (Super_Population)
  WHERE SAFE_DIVIDE(alt_allele_cnt, 2 * ps.pop_size) >= 0.05
)
SELECT
  Super_Population                             AS super_population,
  pop_size,
  TRUE                                         AS is_common,
  samples_with_alt                             AS num_samples_with_variant,
  COUNT(*)                                     AS variants_shared_by_that_many_samples
FROM common_variants
GROUP BY super_population, pop_size, is_common, num_samples_with_variant
ORDER BY super_population, num_samples_with_variant;