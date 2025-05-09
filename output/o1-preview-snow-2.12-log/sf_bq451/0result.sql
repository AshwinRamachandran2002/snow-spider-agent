WITH snp_variants AS (
    SELECT t."reference_name", t."start", t."end", t."reference_bases", t."alternate_bases", t."call"
    FROM "_1000_GENOMES"."_1000_GENOMES"."VARIANTS" t
    WHERE t."reference_name" = 'X'
      AND t."start" NOT BETWEEN 59999 AND 2699519
      AND t."start" NOT BETWEEN 154931042 AND 155260559
      AND t."reference_bases" IS NOT NULL
      AND LENGTH(t."reference_bases") = 1
),
alternate_bases_lengths AS (
    SELECT
       t."reference_name",
       t."start",
       t."end",
       t."call",
       MAX(LENGTH(ab.value::string)) AS max_alt_length,
       MIN(LENGTH(ab.value::string)) AS min_alt_length
    FROM snp_variants t,
         TABLE(FLATTEN(input => t."alternate_bases")) ab
    GROUP BY
       t."reference_name",
       t."start",
       t."end",
       t."call"
),
filtered_snp_variants AS (
    SELECT s.*
    FROM snp_variants s
    INNER JOIN alternate_bases_lengths al
    ON s."reference_name" = al."reference_name" AND s."start" = al."start" AND s."end" = al."end" AND s."call" = al."call"
    WHERE al.max_alt_length = 1 AND al.min_alt_length = 1
),
genotype_data AS (
    SELECT
      f.value:"call_set_name"::STRING AS "sample_id",
      f.value:"genotype" AS "genotype_array"
    FROM filtered_snp_variants AS t,
         LATERAL FLATTEN(input => t."call") f
),
sample_info AS (
    SELECT DISTINCT "Sample" AS "sample_id", LOWER("Gender") AS "gender"
    FROM "_1000_GENOMES"."_1000_GENOMES"."SAMPLE_INFO"
),
genotype_with_gender AS (
    SELECT gd."sample_id", gd."genotype_array", si."gender"
    FROM genotype_data gd
    LEFT JOIN sample_info si ON gd."sample_id" = si."sample_id"
),
allele_types AS (
    SELECT
      "sample_id",
      TRY_TO_NUMBER("genotype_array"[0]::STRING) AS "allele0",
      CASE
        WHEN ARRAY_SIZE("genotype_array") > 1 THEN TRY_TO_NUMBER("genotype_array"[1]::STRING)
        ELSE NULL
      END AS "allele1",
      "gender",
      CASE
        WHEN "gender" = 'male' AND TRY_TO_NUMBER("genotype_array"[0]::STRING) = 0 THEN 'homozygous_reference'
        WHEN "gender" = 'male' AND TRY_TO_NUMBER("genotype_array"[0]::STRING) > 0 THEN 'homozygous_alternate'
        WHEN "gender" = 'female' AND TRY_TO_NUMBER("genotype_array"[0]::STRING) = 0 AND TRY_TO_NUMBER("genotype_array"[1]::STRING) = 0 THEN 'homozygous_reference'
        WHEN "gender" = 'female' AND ((TRY_TO_NUMBER("genotype_array"[0]::STRING) = 0 AND TRY_TO_NUMBER("genotype_array"[1]::STRING) > 0) OR (TRY_TO_NUMBER("genotype_array"[0]::STRING) > 0 AND TRY_TO_NUMBER("genotype_array"[1]::STRING) = 0)) THEN 'heterozygous_alternate'
        WHEN "gender" = 'female' AND TRY_TO_NUMBER("genotype_array"[0]::STRING) = TRY_TO_NUMBER("genotype_array"[1]::STRING) AND TRY_TO_NUMBER("genotype_array"[0]::STRING) > 0 THEN 'homozygous_alternate'
        ELSE 'other'
      END AS "allele_type"
    FROM genotype_with_gender
    WHERE "gender" IN ('male', 'female')
),
final_counts AS (
    SELECT
      "sample_id",
      COUNT(CASE WHEN "allele_type" = 'homozygous_reference' THEN 1 END) AS "homozygous_reference_alleles",
      COUNT(CASE WHEN "allele_type" = 'homozygous_alternate' THEN 1 END) AS "homozygous_alternate_alleles",
      COUNT(CASE WHEN "allele_type" = 'heterozygous_alternate' THEN 1 END) AS "heterozygous_alternate_alleles",
      COUNT(*) AS "total_callable_sites",
      COUNT(CASE WHEN "allele_type" IN ('homozygous_alternate', 'heterozygous_alternate') THEN 1 END) AS "total_SNVs"
    FROM allele_types
    GROUP BY "sample_id"
)
SELECT
  "sample_id",
  "homozygous_reference_alleles",
  "homozygous_alternate_alleles",
  "heterozygous_alternate_alleles",
  "total_callable_sites",
  "total_SNVs",
  ROUND(
    "heterozygous_alternate_alleles" * 100.0 /
    NULLIF("total_SNVs", 0),
    4
  ) AS "percentage_heterozygous_alternate_alleles",
  ROUND(
    "homozygous_alternate_alleles" * 100.0 /
    NULLIF("total_SNVs", 0),
    4
  ) AS "percentage_homozygous_alternate_alleles"
FROM final_counts
ORDER BY "sample_id";