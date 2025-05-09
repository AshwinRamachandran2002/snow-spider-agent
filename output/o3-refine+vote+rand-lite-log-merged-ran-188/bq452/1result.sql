-- Identify chr-12 variants with Yates-corrected χ² ≥ 29.71679
-- and all four expected counts ≥ 5
WITH allele_counts AS (
  SELECT
    v.start                                                  AS start_pos,
    v.end                                                    AS end_pos,
    -- alt / ref allele tallies in EAS (cases)
    SUM(CASE WHEN s.super_population = 'EAS'
             THEN (SELECT COUNTIF(g = 1) FROM UNNEST(c.genotype) g)
             ELSE 0 END)                                    AS a,   -- cases, alt
    SUM(CASE WHEN s.super_population = 'EAS'
             THEN (SELECT COUNTIF(g = 0) FROM UNNEST(c.genotype) g)
             ELSE 0 END)                                    AS b,   -- cases, ref
    -- alt / ref allele tallies in non-EAS (controls)
    SUM(CASE WHEN s.super_population <> 'EAS'
             THEN (SELECT COUNTIF(g = 1) FROM UNNEST(c.genotype) g)
             ELSE 0 END)                                    AS c,   -- controls, alt
    SUM(CASE WHEN s.super_population <> 'EAS'
             THEN (SELECT COUNTIF(g = 0) FROM UNNEST(c.genotype) g)
             ELSE 0 END)                                    AS d    -- controls, ref
  FROM   `genomics-public-data.1000_genomes.variants`                    AS v
  CROSS  JOIN UNNEST(v.call)                                             AS c
  JOIN   `bigquery-public-data.human_genome_variants.1000_genomes_sample_info` AS s
         ON s.sample = c.call_set_name
  WHERE  v.reference_name = '12'
  GROUP  BY start_pos, end_pos
), exp_ok AS (
  -- compute expected counts; keep rows where each expected ≥ 5
  SELECT *,
         (a+b)*(a+c)/(a+b+c+d)   AS e_a,
         (a+b)*(b+d)/(a+b+c+d)   AS e_b,
         (c+d)*(a+c)/(a+b+c+d)   AS e_c,
         (c+d)*(b+d)/(a+b+c+d)   AS e_d,
         (a+b+c+d)               AS N
  FROM   allele_counts
  WHERE  (a+b+c+d) > 0
         AND (a+b)*(a+c)/(a+b+c+d) >= 5
         AND (a+b)*(b+d)/(a+b+c+d) >= 5
         AND (c+d)*(a+c)/(a+b+c+d) >= 5
         AND (c+d)*(b+d)/(a+b+c+d) >= 5
), stats AS (
  -- Yates-corrected χ² statistic
  SELECT
    start_pos,
    end_pos,
    SAFE_DIVIDE(
      POW(ABS(CAST(a AS FLOAT64)*d - CAST(b AS FLOAT64)*c) - 0.5*N, 2) * N,
      CAST(a+b AS FLOAT64) * CAST(c+d AS FLOAT64) *
      CAST(a+c AS FLOAT64) * CAST(b+d AS FLOAT64)
    ) AS chi_sq
  FROM exp_ok
)
SELECT
  start_pos AS start,
  end_pos   AS end_position,
  chi_sq
FROM  stats
WHERE chi_sq >= 29.71679
ORDER BY chi_sq DESC;