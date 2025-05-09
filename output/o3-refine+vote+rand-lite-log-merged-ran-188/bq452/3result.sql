WITH allele_counts AS (   -- 1) count ref/alt alleles in EAS vs non-EAS
  SELECT
    v.`start`,
    v.`end`,
    SUM(IF(si.Super_Population = 'EAS' AND g = 0, 1, 0)) AS a,   -- EAS ref
    SUM(IF(si.Super_Population = 'EAS' AND g != 0, 1, 0)) AS b,  -- EAS alt
    SUM(IF(si.Super_Population != 'EAS' AND g = 0, 1, 0)) AS c,  -- non-EAS ref
    SUM(IF(si.Super_Population != 'EAS' AND g != 0, 1, 0)) AS d  -- non-EAS alt
  FROM `genomics-public-data.1000_genomes.variants`      AS v
  CROSS JOIN UNNEST(v.call)                              AS c
  JOIN `genomics-public-data.1000_genomes.sample_info`   AS si
    ON si.Sample = c.call_set_name
  CROSS JOIN UNNEST(c.genotype)                          AS g
  WHERE v.reference_name = '12'    -- chromosome-12
    AND g != -1                    -- exclude missing alleles
  GROUP BY v.`start`, v.`end`
),
expected AS (          -- 2) compute expected counts
  SELECT
    *,
    (a+b)*(a+c)/(a+b+c+d) AS exp_a,
    (a+b)*(b+d)/(a+b+c+d) AS exp_b,
    (c+d)*(a+c)/(a+b+c+d) AS exp_c,
    (c+d)*(b+d)/(a+b+c+d) AS exp_d
  FROM allele_counts
),
valid AS (             -- 3) keep 2×2 tables with all expected ≥ 5
  SELECT *
  FROM expected
  WHERE exp_a >= 5 AND exp_b >= 5 AND exp_c >= 5 AND exp_d >= 5
)
SELECT                  -- 4) Yates-corrected χ² & final filter
  `start`,
  `end`,
  ( (a+b+c+d) * POW(ABS(a*d - b*c) - (a+b+c+d)/2.0, 2) ) /
  ( (a+b)*(c+d)*(a+c)*(b+d) ) AS chi2_yates
FROM valid
WHERE ( (a+b+c+d) * POW(ABS(a*d - b*c) - (a+b+c+d)/2.0, 2) ) /
      ( (a+b)*(c+d)*(a+c)*(b+d) ) >= 29.71679
ORDER BY chi2_yates DESC;