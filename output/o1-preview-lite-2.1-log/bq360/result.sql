SELECT specialization, specialist_count
FROM (
  SELECT
    ts.specialization,
    ts.specialist_count,
    AVG(ts.specialist_count) OVER () AS avg_specialist_count,
    ABS(ts.specialist_count - AVG(ts.specialist_count) OVER ()) AS diff_from_avg
  FROM (
    SELECT tcs.`specialization`, COUNT(*) AS specialist_count
    FROM `bigquery-public-data.nppes.npi_raw` AS nr
    JOIN `bigquery-public-data.nppes.healthcare_provider_taxonomy_code_set` AS tcs
      ON nr.`healthcare_provider_taxonomy_code_1` = tcs.`code`
    WHERE LOWER(nr.`provider_business_practice_location_address_city_name`) = 'mountain view'
      AND nr.`provider_business_practice_location_address_state_name` = 'CA'
      AND tcs.`specialization` IS NOT NULL AND tcs.`specialization` != ''
    GROUP BY tcs.`specialization`
    ORDER BY specialist_count DESC
    LIMIT 10
  ) AS ts
)
ORDER BY diff_from_avg ASC
LIMIT 1;