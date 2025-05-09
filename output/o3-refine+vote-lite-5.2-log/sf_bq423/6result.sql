/* Image‑type Health ads from verified Cypriot advertisers that were shown in Croatia
   during 2023 — return the page URL of the ad with the highest upper‑bound
   of times shown (only ads whose times‑shown data is already available). */
WITH exploded AS (
    SELECT
        cs."creative_id",
        cs."creative_page_url",
        cs."ad_format_type",
        cs."topic",
        cs."advertiser_location",
        cs."advertiser_verification_status",
        cs."audience_selection_approach_info",
        rs.value:"region_code"::string                 AS region_code,
        rs.value:"first_shown"::date                   AS first_shown,
        rs.value:"last_shown"::date                    AS last_shown,
        rs.value:"times_shown_availability_date"::date AS times_shown_availability_date,
        rs.value:"times_shown_upper_bound"::integer    AS times_shown_upper_bound
    FROM GOOGLE_ADS.GOOGLE_ADS_TRANSPARENCY_CENTER."CREATIVE_STATS" cs,
         LATERAL FLATTEN ( INPUT => cs."region_stats" ) rs
)
SELECT "creative_page_url"
FROM (
    SELECT
        "creative_id",
        "creative_page_url",
        times_shown_upper_bound,
        ROW_NUMBER() OVER (ORDER BY times_shown_upper_bound DESC NULLS LAST,
                                  "creative_id") AS rn
    FROM exploded
    WHERE region_code                    = 'HR'                -- Croatia
      AND first_shown    >  DATE '2023-01-01'                  -- strictly after
      AND last_shown     <  DATE '2024-01-01'                  -- strictly before
      AND "ad_format_type"              = 'IMAGE'
      AND "topic" ILIKE 'Health%'                               -- Health topic
      AND "advertiser_location"         = 'CY'                 -- Cyprus
      AND "advertiser_verification_status" = 'VERIFIED'
      AND times_shown_availability_date IS NULL                -- data available
      AND times_shown_upper_bound IS NOT NULL
      /* every targeting method must be used (not UNUSED) */
      AND COALESCE("audience_selection_approach_info":"contextual_signals"::string,
                   'CRITERIA_UNUSED')        <> 'CRITERIA_UNUSED'
      AND COALESCE("audience_selection_approach_info":"customer_lists"::string,
                   'CRITERIA_UNUSED')        <> 'CRITERIA_UNUSED'
      AND COALESCE("audience_selection_approach_info":"demographic_info"::string,
                   'CRITERIA_UNUSED')        <> 'CRITERIA_UNUSED'
      AND COALESCE("audience_selection_approach_info":"geo_location"::string,
                   'CRITERIA_UNUSED')        <> 'CRITERIA_UNUSED'
      AND COALESCE("audience_selection_approach_info":"topics_of_interest"::string,
                   'CRITERIA_UNUSED')        <> 'CRITERIA_UNUSED'
) ranked
WHERE rn = 1;