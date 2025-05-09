/* Hardy‑Weinberg statistics for chr 17 : 41 196 311 – 41 277 499 */
WITH genotype_counts AS (
  SELECT
    v.start AS start_position,
    v.end   AS end_position,
    COUNT(*) AS total_genotypes,
    COUNTIF(ARRAY_LENGTH(c.genotype)=2
            AND c.genotype[OFFSET(0)] = 0
            AND c.genotype[OFFSET(1)] = 0)                                  AS observed_hom_ref,
    COUNTIF(ARRAY_LENGTH(c.genotype)=2
            AND ((c.genotype[OFFSET(0)] = 0 AND c.genotype[OFFSET(1)] = 1) OR
                 (c.genotype[OFFSET(0)] = 1 AND c.genotype[OFFSET(1)] = 0))) AS observed_het,
    COUNTIF(ARRAY_LENGTH(c.genotype)=2
            AND c.genotype[OFFSET(0)] = 1
            AND c.genotype[OFFSET(1)] = 1)                                  AS observed_hom_alt
  FROM `genomics-public-data.1000_genomes.variants` AS v
  CROSS JOIN UNNEST(v.call) AS c
  WHERE v.reference_name = '17'
    AND v.start BETWEEN 41196311 AND 41277499
  GROUP BY start_position, end_position
),
allele_freq AS (
  SELECT
    *,
    SAFE_DIVIDE(2*observed_hom_alt + observed_het,
                2*total_genotypes)                                           AS allele_frequency
  FROM genotype_counts
),
expected AS (
  SELECT
    *,
    (1 - allele_frequency)*(1 - allele_frequency)*total_genotypes            AS expected_hom_ref,
    2*allele_frequency*(1 - allele_frequency)*total_genotypes                AS expected_het,
    allele_frequency*allele_frequency*total_genotypes                        AS expected_hom_alt
  FROM allele_freq
),
hwe AS (
  SELECT
    *,
    ROUND(
      COALESCE(SAFE_DIVIDE(POW(observed_hom_ref - expected_hom_ref,2),expected_hom_ref),0) +
      COALESCE(SAFE_DIVIDE(POW(observed_het     - expected_het    ,2),expected_het    ),0) +
      COALESCE(SAFE_DIVIDE(POW(observed_hom_alt - expected_hom_alt,2),expected_hom_alt),0)
    ,4)                                                                     AS chi_squared
  FROM expected
)
SELECT
  v.reference_name,
  h.start_position,
  h.end_position,
  v.reference_bases,
  ARRAY(SELECT DISTINCT alt FROM UNNEST(v.alternate_bases) AS alt)           AS alternate_bases,
  v.VT                                                                       AS variant_type,
  h.chi_squared,
  h.total_genotypes,
  h.observed_hom_ref,
  h.observed_het,
  h.observed_hom_alt,
  ROUND(h.expected_hom_ref,4)                                                AS expected_hom_ref,
  ROUND(h.expected_het,4)                                                    AS expected_het,
  ROUND(h.expected_hom_alt,4)                                                AS expected_hom_alt,
  ROUND(h.allele_frequency,4)                                                AS allele_frequency,
  ROUND(v.AF,4)                                                              AS allele_frequency_1kg
FROM `genomics-public-data.1000_genomes.variants` AS v
JOIN hwe AS h
  ON v.start = h.start_position
 AND v.end   = h.end_position
WHERE v.reference_name = '17'
  AND v.start BETWEEN 41196311 AND 41277499
ORDER BY h.start_position, h.end_position;