-- Variants on chromosome 12 with Yates‑corrected χ² ≥ 29.71679
WITH sample_groups AS (
  SELECT
    Sample AS sample_id,
    CASE WHEN Super_Population = 'EAS' THEN 1 ELSE 0 END AS is_eas
  FROM `genomics-public-data.1000_genomes.sample_info`
),
allele_counts AS (
  SELECT
    v.start AS start_pos,
    v.end   AS end_pos,
    -- 2×2 contingency‑table allele counts
    SUM(IF(sg.is_eas = 1 AND g > 0, 1, 0)) AS a,  -- EAS  – alt
    SUM(IF(sg.is_eas = 1 AND g = 0, 1, 0)) AS b,  -- EAS  – ref
    SUM(IF(sg.is_eas = 0 AND g > 0, 1, 0)) AS c,  -- non‑EAS – alt
    SUM(IF(sg.is_eas = 0 AND g = 0, 1, 0)) AS d   -- non‑EAS – ref
  FROM `genomics-public-data.1000_genomes.variants` AS v
  JOIN UNNEST(v.call)         AS c
  JOIN sample_groups          AS sg ON sg.sample_id = c.call_set_name
  JOIN UNNEST(c.genotype)     AS g
  WHERE v.reference_name = '12'
  GROUP BY start_pos, end_pos
),
chisq AS (
  SELECT
    start_pos,
    end_pos,
    -- Yates‑corrected χ² statistic
    (POWER(ABS(a*d - b*c) - 0.5, 2) * (a+b+c+d)) /
    NULLIF((a+b)*(c+d)*(a+c)*(b+d), 0) AS chi_sq
  FROM allele_counts
  WHERE
    -- ensure expected counts ≥ 5 in every cell
    (a+b)*(a+c)/(a+b+c+d) >= 5 AND
    (c+d)*(a+c)/(a+b+c+d) >= 5 AND
    (a+b)*(b+d)/(a+b+c+d) >= 5 AND
    (c+d)*(b+d)/(a+b+c+d) >= 5
)
SELECT
  start_pos AS start_position,
  end_pos   AS end_position,
  chi_sq
FROM chisq
WHERE chi_sq >= 29.71679
ORDER BY chi_sq DESC;