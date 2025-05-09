WITH ads AS (
    SELECT
        cs."creative_page_url",
        TRY_TO_NUMBER(r.value:"times_shown_upper_bound"::STRING) AS times_shown_upper_bound
    FROM GOOGLE_ADS.GOOGLE_ADS_TRANSPARENCY_CENTER.CREATIVE_STATS cs,
         LATERAL FLATTEN(INPUT => PARSE_JSON(cs."region_stats")) r
    WHERE cs."ad_format_type" = 'IMAGE'
      AND cs."advertiser_verification_status" = 'VERIFIED'
      AND cs."advertiser_location" = 'CY'
      AND (cs."topic" ILIKE 'Health%' OR cs."topic" = 'Health')
      AND r.value:"region_code"::STRING = 'HR'
      AND TO_DATE(r.value:"first_shown"::STRING)  > '2023-01-01'
      AND TO_DATE(r.value:"last_shown"::STRING)   < '2024-01-01'
      AND r.value:"times_shown_availability_date" IS NULL
      AND COALESCE(PARSE_JSON(cs."audience_selection_approach_info"):"demographic_info"::STRING,   'CRITERIA_UNUSED') <> 'CRITERIA_UNUSED'
      AND COALESCE(PARSE_JSON(cs."audience_selection_approach_info"):"geo_location"::STRING,       'CRITERIA_UNUSED') <> 'CRITERIA_UNUSED'
      AND COALESCE(PARSE_JSON(cs."audience_selection_approach_info"):"contextual_signals"::STRING, 'CRITERIA_UNUSED') <> 'CRITERIA_UNUSED'
      AND COALESCE(PARSE_JSON(cs."audience_selection_approach_info"):"customer_lists"::STRING,     'CRITERIA_UNUSED') <> 'CRITERIA_UNUSED'
      AND COALESCE(PARSE_JSON(cs."audience_selection_approach_info"):"topics_of_interest"::STRING, 'CRITERIA_UNUSED') <> 'CRITERIA_UNUSED'
)
SELECT "creative_page_url"
FROM ads
ORDER BY times_shown_upper_bound DESC NULLS LAST
LIMIT 1;