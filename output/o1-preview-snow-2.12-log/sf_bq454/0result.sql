WITH sample_counts AS (
  SELECT
    "Super_Population" AS "Super_Population_Combination",
    COUNT(DISTINCT "Sample") AS "Sample_Count"
  FROM
    "_1000_GENOMES"."_1000_GENOMES"."SAMPLE_INFO"
  GROUP BY
    "Super_Population"
  UNION ALL
  SELECT
    'ASN' AS "Super_Population_Combination",
    COUNT(DISTINCT "Sample") AS "Sample_Count"
  FROM
    "_1000_GENOMES"."_1000_GENOMES"."SAMPLE_INFO"
  WHERE
    "Super_Population" IN ('EAS', 'SAS')
),
variant_counts AS (
  SELECT
    'AFR' AS "Super_Population_Combination",
    v."VT" AS "Variant_Type",
    COUNT(DISTINCT v."reference_name" || ':' || TO_VARCHAR(v."start")) AS "Number_of_Common_Autosomal_Variants"
  FROM
    "_1000_GENOMES"."_1000_GENOMES"."VARIANTS" v
  WHERE
    v."reference_name" NOT IN ('X', 'Y', 'MT')
    AND v."AFR_AF" >= 0.05
  GROUP BY
    v."VT"
  UNION ALL
  SELECT
    'AMR' AS "Super_Population_Combination",
    v."VT" AS "Variant_Type",
    COUNT(DISTINCT v."reference_name" || ':' || TO_VARCHAR(v."start")) AS "Number_of_Common_Autosomal_Variants"
  FROM
    "_1000_GENOMES"."_1000_GENOMES"."VARIANTS" v
  WHERE
    v."reference_name" NOT IN ('X', 'Y', 'MT')
    AND v."AMR_AF" >= 0.05
  GROUP BY
    v."VT"
  UNION ALL
  SELECT
    'EUR' AS "Super_Population_Combination",
    v."VT" AS "Variant_Type",
    COUNT(DISTINCT v."reference_name" || ':' || TO_VARCHAR(v."start")) AS "Number_of_Common_Autosomal_Variants"
  FROM
    "_1000_GENOMES"."_1000_GENOMES"."VARIANTS" v
  WHERE
    v."reference_name" NOT IN ('X', 'Y', 'MT')
    AND v."EUR_AF" >= 0.05
  GROUP BY
    v."VT"
  UNION ALL
  SELECT
    'ASN' AS "Super_Population_Combination",
    v."VT" AS "Variant_Type",
    COUNT(DISTINCT v."reference_name" || ':' || TO_VARCHAR(v."start")) AS "Number_of_Common_Autosomal_Variants"
  FROM
    "_1000_GENOMES"."_1000_GENOMES"."VARIANTS" v
  WHERE
    v."reference_name" NOT IN ('X', 'Y', 'MT')
    AND v."ASN_AF" >= 0.05
  GROUP BY
    v."VT"
)
SELECT
  vc."Super_Population_Combination",
  sc."Sample_Count" * 2 AS "Total_Population_Size",
  vc."Variant_Type",
  sc."Sample_Count" AS "Sample_Count",
  vc."Number_of_Common_Autosomal_Variants"
FROM
  variant_counts vc
JOIN
  sample_counts sc
  ON vc."Super_Population_Combination" = sc."Super_Population_Combination"
ORDER BY
  vc."Super_Population_Combination", vc."Variant_Type";