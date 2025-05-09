WITH providers_in_mountain_view AS (
  SELECT "npi",
    "healthcare_provider_taxonomy_code_1",
    "healthcare_provider_taxonomy_code_2",
    "healthcare_provider_taxonomy_code_3",
    "healthcare_provider_taxonomy_code_4",
    "healthcare_provider_taxonomy_code_5",
    "healthcare_provider_taxonomy_code_6",
    "healthcare_provider_taxonomy_code_7",
    "healthcare_provider_taxonomy_code_8",
    "healthcare_provider_taxonomy_code_9",
    "healthcare_provider_taxonomy_code_10",
    "healthcare_provider_taxonomy_code_11",
    "healthcare_provider_taxonomy_code_12",
    "healthcare_provider_taxonomy_code_13",
    "healthcare_provider_taxonomy_code_14",
    "healthcare_provider_taxonomy_code_15"
  FROM NPPES.NPPES.NPI_RAW
  WHERE "provider_business_practice_location_address_city_name" ILIKE 'MOUNTAIN VIEW'
    AND "provider_business_practice_location_address_state_name" = 'CA'
), taxonomy_codes_unpivoted AS (
  SELECT "npi", "taxonomy_code"
  FROM providers_in_mountain_view
  UNPIVOT (
    "taxonomy_code" FOR "taxonomy_col" IN (
      "healthcare_provider_taxonomy_code_1",
      "healthcare_provider_taxonomy_code_2",
      "healthcare_provider_taxonomy_code_3",
      "healthcare_provider_taxonomy_code_4",
      "healthcare_provider_taxonomy_code_5",
      "healthcare_provider_taxonomy_code_6",
      "healthcare_provider_taxonomy_code_7",
      "healthcare_provider_taxonomy_code_8",
      "healthcare_provider_taxonomy_code_9",
      "healthcare_provider_taxonomy_code_10",
      "healthcare_provider_taxonomy_code_11",
      "healthcare_provider_taxonomy_code_12",
      "healthcare_provider_taxonomy_code_13",
      "healthcare_provider_taxonomy_code_14",
      "healthcare_provider_taxonomy_code_15"
    )
  )
  WHERE "taxonomy_code" IS NOT NULL
), taxonomy_with_specialization AS (
  SELECT tcu."npi", t."specialization"
  FROM taxonomy_codes_unpivoted tcu
  LEFT JOIN NPPES.NPPES.HEALTHCARE_PROVIDER_TAXONOMY_CODE_SET t
    ON tcu."taxonomy_code" = t."code"
  WHERE t."specialization" IS NOT NULL AND t."specialization" <> ''
), specialization_counts AS (
  SELECT "specialization", COUNT(DISTINCT "npi") AS "specialist_count"
  FROM taxonomy_with_specialization
  GROUP BY "specialization"
), top_specializations AS (
  SELECT "specialization", "specialist_count"
  FROM specialization_counts
  ORDER BY "specialist_count" DESC NULLS LAST
  LIMIT 10
), avg_specialist_count AS (
  SELECT AVG("specialist_count") AS "avg_count"
  FROM top_specializations
), result AS (
  SELECT ts."specialization", ts."specialist_count"
  FROM top_specializations ts, avg_specialist_count
  ORDER BY ABS(ts."specialist_count" - avg_specialist_count."avg_count") ASC NULLS LAST
  LIMIT 1
)
SELECT "specialization", "specialist_count"
FROM result;