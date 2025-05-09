WITH variant_pops AS (
  SELECT
    v."VT" AS Variant_Type,
    ARRAY_SORT(ARRAY_COMPACT(
      ARRAY_CONSTRUCT(
        CASE WHEN v."AFR_AF" >= 0.05 THEN 'AFR' END,
        CASE WHEN v."AMR_AF" >= 0.05 THEN 'AMR' END,
        CASE WHEN v."EUR_AF" >= 0.05 THEN 'EUR' END,
        CASE WHEN v."ASN_AF" >= 0.05 THEN 'EAS' END
      )
    )) AS super_pops_array
  FROM "_1000_GENOMES"."_1000_GENOMES"."VARIANTS" v
  WHERE v."reference_name" NOT IN ('X', 'Y', 'MT')
),
sample_counts AS (
  SELECT "Super_Population", COUNT(DISTINCT "Sample") AS sample_count
  FROM "_1000_GENOMES"."_1000_GENOMES"."SAMPLE_INFO"
  WHERE "Super_Population" IN ('AFR', 'AMR', 'EUR', 'EAS')
  GROUP BY "Super_Population"
),
combination_counts AS (
  SELECT
    ARRAY_TO_STRING(vp.super_pops_array, '_') AS Super_Population_Combination,
    vp.Variant_Type,
    COUNT(*) AS Number_of_Common_Autosomal_Variants
  FROM variant_pops vp
  GROUP BY Super_Population_Combination, vp.Variant_Type
),
total_population_sizes AS (
  SELECT
    c.Super_Population_Combination,
    SUM(s.sample_count) AS Total_Population_Size
  FROM (
    SELECT DISTINCT
      ARRAY_TO_STRING(vp.super_pops_array, '_') AS Super_Population_Combination,
      vp.super_pops_array
    FROM variant_pops vp
  ) c,
  LATERAL FLATTEN(INPUT => c.super_pops_array) sp
  JOIN sample_counts s
    ON s."Super_Population" = sp.VALUE
  GROUP BY c.Super_Population_Combination
)
SELECT
  cc.Super_Population_Combination,
  tps.Total_Population_Size,
  cc.Variant_Type,
  tps.Total_Population_Size AS Sample_Count,
  cc.Number_of_Common_Autosomal_Variants
FROM combination_counts cc
JOIN total_population_sizes tps
  ON cc.Super_Population_Combination = tps.Super_Population_Combination
ORDER BY
  cc.Super_Population_Combination,
  cc.Variant_Type;