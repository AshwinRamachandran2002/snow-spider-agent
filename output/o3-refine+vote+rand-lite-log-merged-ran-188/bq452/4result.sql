/*  Yates-corrected χ² test for chromosome-12 variants
    CASES    : samples in EAS super-population
    CONTROLS : samples in any other super-population
    Allele 0 = reference, allele ≠0 = alternate
    Keep variants whose four expected counts ≥ 5
    and χ² ≥ 29.71679                                          */

WITH allele_rows AS (
  SELECT
    v.start_position                         AS start_pos,
    v.end_position                           AS end_pos,
    IF(allele = 0, 0, 1)                     AS allele_bin,   -- 0 = ref, 1 = alt
    si.super_population                      AS super_pop
  FROM `bigquery-public-data.human_genome_variants.1000_genomes_phase_3_variants_20150220` AS v
  JOIN UNNEST(v.call)                  AS c
  JOIN UNNEST(c.genotype)              AS allele
  LEFT JOIN `bigquery-public-data.human_genome_variants.1000_genomes_sample_info` AS si
         ON si.sample = c.name                     -- sample ID
  WHERE v.reference_name = '12'                    -- chromosome 12 only
        AND allele IS NOT NULL
        AND allele >= 0                            -- skip missing (-1)
),

counts AS (
  SELECT
    start_pos,
    end_pos,
    SUM(CASE WHEN super_pop = 'EAS'  AND allele_bin = 0 THEN 1 ELSE 0 END) AS a_ref,
    SUM(CASE WHEN super_pop = 'EAS'  AND allele_bin = 1 THEN 1 ELSE 0 END) AS b_alt,
    SUM(CASE WHEN super_pop <> 'EAS' AND allele_bin = 0 THEN 1 ELSE 0 END) AS c_ref,
    SUM(CASE WHEN super_pop <> 'EAS' AND allele_bin = 1 THEN 1 ELSE 0 END) AS d_alt
  FROM allele_rows
  GROUP BY start_pos, end_pos
),

stats AS (
  SELECT
    start_pos,
    end_pos,
    a_ref, b_alt, c_ref, d_alt,
    (a_ref + b_alt)                 AS row_cases,
    (c_ref + d_alt)                 AS row_controls,
    (a_ref + c_ref)                 AS col_ref,
    (b_alt + d_alt)                 AS col_alt,
    (a_ref + b_alt + c_ref + d_alt) AS N
  FROM counts
  WHERE (a_ref + b_alt + c_ref + d_alt) > 0          -- safety
),

qualified AS (
  SELECT
    *,
    -- Yates-corrected χ² statistic
    POW(ABS(a_ref*d_alt - b_alt*c_ref) - N/2.0, 2) * N /
    ((a_ref+b_alt)*(c_ref+d_alt)*(a_ref+c_ref)*(b_alt+d_alt)) AS chi_sq
  FROM stats
  WHERE
        row_cases   * col_ref / N >= 5
    AND row_cases   * col_alt / N >= 5
    AND row_controls* col_ref / N >= 5
    AND row_controls* col_alt / N >= 5
)

SELECT
  start_pos AS start_position,
  end_pos   AS end_position,
  chi_sq
FROM qualified
WHERE chi_sq >= 29.71679
ORDER BY chi_sq DESC;