WITH candidate_ads AS (
    SELECT
        cs."creative_page_url",
        region.value:"times_shown_upper_bound"::NUMBER      AS upper_bound
    FROM "GOOGLE_ADS"."GOOGLE_ADS_TRANSPARENCY_CENTER"."CREATIVE_STATS"  cs
         /* expand the per-region statistics                                     */
         , LATERAL FLATTEN( INPUT => PARSE_JSON(cs."region_stats") )            region
         /* turn the audience-selection JSON string into VARIANT for filtering   */
         , LATERAL (SELECT PARSE_JSON(cs."audience_selection_approach_info") 
                       AS asi)                                                  asi_tbl
    WHERE
          /* basic ad-level filters */
          cs."ad_format_type"              = 'IMAGE'
      AND cs."topic"                       = 'Health'
      AND cs."advertiser_verification_status" = 'VERIFIED'
      AND cs."advertiser_location"         = 'CY'
          /* audience-selection must actively use every method (≠ CRITERIA_UNUSED) */
      AND asi_tbl.asi:"demographic_info"::STRING      <> 'CRITERIA_UNUSED'
      AND asi_tbl.asi:"geo_location"::STRING          <> 'CRITERIA_UNUSED'
      AND asi_tbl.asi:"contextual_signals"::STRING    <> 'CRITERIA_UNUSED'
      AND asi_tbl.asi:"customer_lists"::STRING        <> 'CRITERIA_UNUSED'
      AND asi_tbl.asi:"topics_of_interest"::STRING    <> 'CRITERIA_UNUSED'
          /* region-level requirements (Croatia = HR) */
      AND region.value:"region_code"::STRING          = 'HR'
      AND region.value:"times_shown_availability_date" IS NULL          -- data already available
      AND region.value:"first_shown"::DATE  >  '2023-01-01'
      AND region.value:"last_shown"::DATE   <  '2024-01-01'
      AND region.value:"times_shown_upper_bound"      IS NOT NULL
)
SELECT  "creative_page_url"
FROM    candidate_ads
ORDER BY upper_bound DESC NULLS LAST
LIMIT 1;