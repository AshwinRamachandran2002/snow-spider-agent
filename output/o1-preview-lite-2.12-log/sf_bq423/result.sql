WITH base_ads AS (
    SELECT t.*,
           f_region.value:"times_shown_upper_bound"::NUMBER AS "times_shown_upper_bound"
    FROM "GOOGLE_ADS"."GOOGLE_ADS_TRANSPARENCY_CENTER"."CREATIVE_STATS" t,
         LATERAL FLATTEN(input => t."region_stats") f_region
    WHERE t."ad_format_type" = 'IMAGE'
      AND t."topic" = 'Health'
      AND t."advertiser_location" = 'CY'
      AND t."advertiser_verification_status" = 'VERIFIED'
      AND f_region.value:"region_code"::STRING = 'HR'
      AND f_region.value:"first_shown"::DATE > '2023-01-01'
      AND f_region.value:"last_shown"::DATE < '2024-01-01'
)
SELECT ba."creative_page_url"
FROM base_ads ba
ORDER BY ba."times_shown_upper_bound" DESC NULLS LAST
LIMIT 1;