SELECT
  sample_id,
  SUM(homo_ref) AS homozygous_reference_alleles,
  SUM(homo_alt) AS homozygous_alternate_alleles,
  SUM(het_alt) AS heterozygous_alternate_alleles,
  COUNT(*) AS total_callable_sites,
  SUM(homo_alt + het_alt) AS total_SNVs,
  CASE
    WHEN SUM(homo_alt + het_alt) > 0 THEN ROUND((SUM(het_alt) / SUM(homo_alt + het_alt)) * 100, 4)
    ELSE 0
  END AS percentage_heterozygous_alternate_alleles,
  CASE
    WHEN SUM(homo_alt + het_alt) > 0 THEN ROUND((SUM(homo_alt) / SUM(homo_alt + het_alt)) * 100, 4)
    ELSE 0
  END AS percentage_homozygous_alternate_alleles
FROM (
  SELECT
    f.value:"call_set_name"::STRING AS sample_id,
    CASE
      WHEN ARRAY_SIZE(f.value:"genotype") = 1 THEN
        CASE
          WHEN f.value:"genotype"[0] = 0 THEN 1
          ELSE 0
        END
      WHEN ARRAY_SIZE(f.value:"genotype") = 2 THEN
        CASE
          WHEN f.value:"genotype"[0] = 0 AND f.value:"genotype"[1] = 0 THEN 1
          ELSE 0
        END
      ELSE 0
    END AS homo_ref,
    CASE
      WHEN ARRAY_SIZE(f.value:"genotype") = 1 THEN
        CASE
          WHEN f.value:"genotype"[0] > 0 THEN 1
          ELSE 0
        END
      WHEN ARRAY_SIZE(f.value:"genotype") = 2 THEN
        CASE
          WHEN f.value:"genotype"[0] > 0 AND f.value:"genotype"[1] > 0 AND f.value:"genotype"[0] = f.value:"genotype"[1] THEN 1
          ELSE 0
        END
      ELSE 0
    END AS homo_alt,
    CASE
      WHEN ARRAY_SIZE(f.value:"genotype") = 2 THEN
        CASE
          WHEN f.value:"genotype"[0] != f.value:"genotype"[1] AND f.value:"genotype"[0] IS NOT NULL AND f.value:"genotype"[1] IS NOT NULL THEN 1
          ELSE 0
        END
      ELSE 0
    END AS het_alt
  FROM "_1000_GENOMES"."_1000_GENOMES"."VARIANTS" t,
    LATERAL FLATTEN(input => t."call") f,
    LATERAL FLATTEN(input => t."alternate_bases") ab
  WHERE t."reference_name" = 'X'
    AND t."start" NOT BETWEEN 59999 AND 2699519
    AND t."start" NOT BETWEEN 154931042 AND 155260559
    AND LENGTH(t."reference_bases") = 1
    AND LENGTH(ab.value::STRING) = 1
) sub
GROUP BY sample_id;