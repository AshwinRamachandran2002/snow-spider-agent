WITH variant_calls AS (
  SELECT
    v."reference_name",
    v."start",
    v."end",
    v."reference_bases",
    ARRAY_TO_STRING(v."alternate_bases", ',') AS "alternate_bases",
    v."VT" AS "variant_type",
    v."AF",
    c.value:"genotype" AS "genotype"
  FROM
    "_1000_GENOMES"."_1000_GENOMES"."VARIANTS" v,
    LATERAL FLATTEN(input => v."call") c
  WHERE
    v."reference_name" = '17' AND v."start" BETWEEN 41196311 AND 41277499
),
genotype_counts AS (
  SELECT
    "reference_name",
    "start",
    "end",
    "reference_bases",
    "alternate_bases",
    "variant_type",
    "AF",
    CASE
      WHEN "genotype"[0] = 0 AND "genotype"[1] = 0 THEN 'hom_ref'
      WHEN ("genotype"[0] = 0 AND "genotype"[1] = 1) OR ("genotype"[0] = 1 AND "genotype"[1] = 0) THEN 'het'
      WHEN "genotype"[0] = 1 AND "genotype"[1] = 1 THEN 'hom_alt'
      ELSE NULL
    END AS "genotype_type"
  FROM
    variant_calls
  WHERE
    "genotype"[0] IS NOT NULL AND "genotype"[1] IS NOT NULL
),
counts AS (
  SELECT
    "reference_name",
    "start",
    "end",
    "reference_bases",
    "alternate_bases",
    "variant_type",
    "AF",
    SUM(CASE WHEN "genotype_type" = 'hom_ref' THEN 1 ELSE 0 END) AS observed_homo_ref,
    SUM(CASE WHEN "genotype_type" = 'het' THEN 1 ELSE 0 END) AS observed_heterozygous,
    SUM(CASE WHEN "genotype_type" = 'hom_alt' THEN 1 ELSE 0 END) AS observed_homo_alt,
    COUNT(*) AS total_samples
  FROM
    genotype_counts
  GROUP BY
    "reference_name",
    "start",
    "end",
    "reference_bases",
    "alternate_bases",
    "variant_type",
    "AF"
),
expected_counts AS (
  SELECT
    *,
    (1 - "AF") AS "p",
    "AF" AS "q",
    total_samples * POWER(1 - "AF", 2) AS expected_homo_ref,
    total_samples * 2 * (1 - "AF") * "AF" AS expected_heterozygous,
    total_samples * POWER("AF", 2) AS expected_homo_alt
  FROM
    counts
),
chi_squared AS (
  SELECT
    "reference_name",
    "start",
    "end",
    "reference_bases",
    "alternate_bases",
    "variant_type",
    ROUND(
      CASE WHEN expected_homo_ref > 0 THEN POWER(observed_homo_ref - expected_homo_ref, 2) / expected_homo_ref ELSE 0 END +
      CASE WHEN expected_heterozygous > 0 THEN POWER(observed_heterozygous - expected_heterozygous, 2) / expected_heterozygous ELSE 0 END +
      CASE WHEN expected_homo_alt > 0 THEN POWER(observed_homo_alt - expected_homo_alt, 2) / expected_homo_alt ELSE 0 END
    , 4) AS chi_squared_score,
    observed_homo_ref,
    observed_heterozygous,
    observed_homo_alt,
    ROUND(expected_homo_ref, 4) AS expected_homo_ref,
    ROUND(expected_heterozygous, 4) AS expected_heterozygous,
    ROUND(expected_homo_alt, 4) AS expected_homo_alt,
    ROUND("AF", 4) AS allele_frequency
  FROM
    expected_counts
)
SELECT
  "reference_name",
  "start",
  "end",
  "reference_bases",
  "alternate_bases",
  "variant_type",
  chi_squared_score,
  observed_homo_ref,
  observed_heterozygous,
  observed_homo_alt,
  expected_homo_ref,
  expected_heterozygous,
  expected_homo_alt,
  allele_frequency
FROM
  chi_squared
ORDER BY
  "start";