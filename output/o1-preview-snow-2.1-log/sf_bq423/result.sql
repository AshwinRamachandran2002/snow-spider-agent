SELECT
  t."creative_page_url"
FROM
  GOOGLE_ADS.GOOGLE_ADS_TRANSPARENCY_CENTER.CREATIVE_STATS t,
  LATERAL FLATTEN(input => t."region_stats") f_region
WHERE
  t."ad_format_type" = 'IMAGE'
  AND t."advertiser_location" = 'CY'
  AND t."advertiser_verification_status" = 'VERIFIED'
  AND t."topic" = 'Health'
  AND f_region.value:"region_code"::STRING = 'HR'
  AND f_region.value:"last_shown"::STRING >= '2023-01-01'
  AND f_region.value:"last_shown"::STRING < '2024-01-01'
ORDER BY
  f_region.value:"times_shown_upper_bound"::NUMBER DESC NULLS LAST
LIMIT 1;