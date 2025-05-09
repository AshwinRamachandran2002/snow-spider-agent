WITH top_specializations AS (
  SELECT
    "primary_specialization",
    COUNT(*) AS "specialist_count"
  FROM (
    SELECT
      COALESCE(
        CASE WHEN "healthcare_provider_primary_taxonomy_switch_1" = 'Y' THEN "healthcare_provider_taxonomy_1_classification" END,
        CASE WHEN "healthcare_provider_primary_taxonomy_switch_2" = 'Y' THEN "healthcare_provider_taxonomy_2_classification" END,
        CASE WHEN "healthcare_provider_primary_taxonomy_switch_3" = 'Y' THEN "healthcare_provider_taxonomy_3_classification" END,
        CASE WHEN "healthcare_provider_primary_taxonomy_switch_4" = 'Y' THEN "healthcare_provider_taxonomy_4_classification" END,
        CASE WHEN "healthcare_provider_primary_taxonomy_switch_5" = 'Y' THEN "healthcare_provider_taxonomy_5_classification" END,
        CASE WHEN "healthcare_provider_primary_taxonomy_switch_6" = 'Y' THEN "healthcare_provider_taxonomy_6_classification" END,
        CASE WHEN "healthcare_provider_primary_taxonomy_switch_7" = 'Y' THEN "healthcare_provider_taxonomy_7_classification" END,
        CASE WHEN "healthcare_provider_primary_taxonomy_switch_8" = 'Y' THEN "healthcare_provider_taxonomy_8_classification" END,
        CASE WHEN "healthcare_provider_primary_taxonomy_switch_9" = 'Y' THEN "healthcare_provider_taxonomy_9_classification" END,
        CASE WHEN "healthcare_provider_primary_taxonomy_switch_10" = 'Y' THEN "healthcare_provider_taxonomy_10_classification" END,
        CASE WHEN "healthcare_provider_primary_taxonomy_switch_11" = 'Y' THEN "healthcare_provider_taxonomy_11_classification" END,
        CASE WHEN "healthcare_provider_primary_taxonomy_switch_12" = 'Y' THEN "healthcare_provider_taxonomy_12_classification" END,
        CASE WHEN "healthcare_provider_primary_taxonomy_switch_13" = 'Y' THEN "healthcare_provider_taxonomy_13_classification" END,
        CASE WHEN "healthcare_provider_primary_taxonomy_switch_14" = 'Y' THEN "healthcare_provider_taxonomy_14_classification" END,
        CASE WHEN "healthcare_provider_primary_taxonomy_switch_15" = 'Y' THEN "healthcare_provider_taxonomy_15_classification" END,
        NULLIF("healthcare_provider_taxonomy_1_classification", ''),
        NULLIF("healthcare_provider_taxonomy_2_classification", ''),
        NULLIF("healthcare_provider_taxonomy_3_classification", ''),
        NULLIF("healthcare_provider_taxonomy_4_classification", ''),
        NULLIF("healthcare_provider_taxonomy_5_classification", ''),
        NULLIF("healthcare_provider_taxonomy_6_classification", ''),
        NULLIF("healthcare_provider_taxonomy_7_classification", ''),
        NULLIF("healthcare_provider_taxonomy_8_classification", ''),
        NULLIF("healthcare_provider_taxonomy_9_classification", ''),
        NULLIF("healthcare_provider_taxonomy_10_classification", ''),
        NULLIF("healthcare_provider_taxonomy_11_classification", ''),
        NULLIF("healthcare_provider_taxonomy_12_classification", ''),
        NULLIF("healthcare_provider_taxonomy_13_classification", ''),
        NULLIF("healthcare_provider_taxonomy_14_classification", ''),
        NULLIF("healthcare_provider_taxonomy_15_classification", '')
      ) AS "primary_specialization"
    FROM NPPES.NPPES.NPI_OPTIMIZED
    WHERE "provider_business_practice_location_address_city_name" ILIKE '%Mountain View%'
      AND "provider_business_practice_location_address_state_name" = 'CA'
  ) AS sub
  WHERE "primary_specialization" IS NOT NULL
  GROUP BY "primary_specialization"
  ORDER BY "specialist_count" DESC NULLS LAST
  LIMIT 10
),
average_count AS (
  SELECT AVG("specialist_count") AS "avg_count"
  FROM top_specializations
)
SELECT
  ts."primary_specialization" AS "Specialization",
  ts."specialist_count" AS "Specialist_Count"
FROM top_specializations ts
CROSS JOIN average_count ac
ORDER BY ABS(ts."specialist_count" - ac."avg_count") ASC
LIMIT 1;