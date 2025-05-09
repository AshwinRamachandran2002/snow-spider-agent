WITH ProviderTaxonomy AS (
  SELECT
    t1."npi",
    t2."specialization"
  FROM
    NPPES.NPPES.NPI_RAW t1
    UNPIVOT (
      taxonomy_code FOR code_num IN (
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
    JOIN NPPES.NPPES.HEALTHCARE_PROVIDER_TAXONOMY_CODE_SET t2
      ON taxonomy_code = t2."code"
  WHERE
    t1."provider_business_practice_location_address_city_name" = 'MOUNTAIN VIEW'
    AND t1."provider_business_practice_location_address_state_name" = 'CA'
    AND taxonomy_code IS NOT NULL
    AND t2."specialization" IS NOT NULL
),
SpecializationCounts AS (
  SELECT
    "specialization",
    COUNT(DISTINCT "npi") AS "Number_of_Distinct_NPIs"
  FROM
    ProviderTaxonomy
  GROUP BY
    "specialization"
),
Top10Specializations AS (
  SELECT
    "specialization",
    "Number_of_Distinct_NPIs"
  FROM
    SpecializationCounts
  ORDER BY
    "Number_of_Distinct_NPIs" DESC
  LIMIT 10
),
AverageCount AS (
  SELECT
    AVG("Number_of_Distinct_NPIs") AS avg_count
  FROM
    Top10Specializations
),
SpecializationClosestToAvg AS (
  SELECT
    "specialization",
    "Number_of_Distinct_NPIs"
  FROM (
    SELECT
      "specialization",
      "Number_of_Distinct_NPIs",
      ABS("Number_of_Distinct_NPIs" - (SELECT avg_count FROM AverageCount)) AS diff_to_avg
    FROM
      Top10Specializations
  ) t
  ORDER BY
    diff_to_avg ASC,
    "specialization"
  LIMIT 1
)
SELECT
  "Specialization",
  "Number_of_Distinct_NPIs"
FROM (
  SELECT
    'Specialization' AS "Specialization",
    'Number_of_Distinct_NPIs' AS "Number_of_Distinct_NPIs",
    0 AS sort_order,
    NULL AS count_order
  UNION ALL
  SELECT
    "specialization",
    TO_VARCHAR("Number_of_Distinct_NPIs"),
    1 AS sort_order,
    "Number_of_Distinct_NPIs" AS count_order
  FROM
    Top10Specializations
  UNION ALL
  SELECT NULL, NULL, 2, NULL
  UNION ALL
  SELECT
    'Specialization with count closest to average:',
    NULL,
    3 AS sort_order,
    NULL AS count_order
  UNION ALL
  SELECT
    "specialization",
    TO_VARCHAR("Number_of_Distinct_NPIs"),
    4 AS sort_order,
    NULL AS count_order
  FROM
    SpecializationClosestToAvg
) t
ORDER BY
  sort_order,
  count_order DESC NULLS LAST;