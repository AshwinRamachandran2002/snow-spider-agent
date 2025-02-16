-- Task: Retrieve the page URLs, first shown time, and last shown time for the five most recently removed ads in the Croatia region (region code 'HR'), ordering the resulting ads by their last shown time in descending order.
SELECT
    "creative_page_url",
    TO_TIMESTAMP(GET("region_stat".value, 'first_shown')) AS "first_shown",
    TO_TIMESTAMP(GET("region_stat".value, 'last_shown')) AS "last_shown"
FROM
    "GOOGLE_ADS"."GOOGLE_ADS_TRANSPARENCY_CENTER"."REMOVED_CREATIVE_STATS",
    LATERAL FLATTEN(input => "region_stats") AS "region_stat"
WHERE
    GET("region_stat".value, 'region_code') = 'HR'
ORDER BY
    "last_shown" DESC
LIMIT 5;