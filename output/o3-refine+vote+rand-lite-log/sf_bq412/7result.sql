WITH region_flat AS (   -- explode the region array and keep only Croatia rows
    SELECT
        rc."creative_page_url",
        rc."audience_selection_approach_info"               AS asi,
        rc."disapproval"                                    AS disapproval_arr,
        region.value                                        AS region_obj
    FROM GOOGLE_ADS.GOOGLE_ADS_TRANSPARENCY_CENTER.REMOVED_CREATIVE_STATS rc,
         LATERAL FLATTEN ( input => rc."region_stats" )     region
    WHERE region.value:"region_code"::string = 'HR'
),
disapproval_flat AS (   -- explode the disapproval array (usually just one element)
    SELECT
        rf."creative_page_url"     AS creative_page_url,   -- alias without quotes for easy reuse
        rf.asi,
        rf.region_obj:"first_shown"::date            AS first_shown,
        rf.region_obj:"last_shown"::date             AS last_shown,
        rf.region_obj:"times_shown_lower_bound"::number  AS times_shown_lower_bound,
        rf.region_obj:"times_shown_upper_bound"::number  AS times_shown_upper_bound,
        rf.region_obj:"times_shown_availability_date"        AS times_shown_availability_date,
        disp.value:"removal_reason"::string          AS removal_reason,
        disp.value:"violation_category"::string      AS violation_category
    FROM region_flat rf,
         LATERAL FLATTEN ( input => rf.disapproval_arr ) disp
),
filtered AS (   -- apply all requested filters
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY creative_page_url ORDER BY last_shown DESC) AS rn
    FROM disapproval_flat
    WHERE times_shown_availability_date IS NULL
      AND times_shown_lower_bound  > 10000
      AND times_shown_upper_bound  < 25000
      AND (
              NVL(asi:"contextual_signals"::string, 'CRITERIA_UNUSED')        <> 'CRITERIA_UNUSED' OR
              NVL(asi:"customer_lists"::string,      'CRITERIA_UNUSED')        <> 'CRITERIA_UNUSED' OR
              NVL(asi:"demographic_info"::string,    'CRITERIA_UNUSED')        <> 'CRITERIA_UNUSED' OR
              NVL(asi:"geo_location"::string,        'CRITERIA_UNUSED')        <> 'CRITERIA_UNUSED' OR
              NVL(asi:"topics_of_interest"::string,  'CRITERIA_UNUSED')        <> 'CRITERIA_UNUSED'
          )
)
SELECT
    creative_page_url            AS "page_url",
    first_shown,
    last_shown,
    removal_reason,
    violation_category,
    times_shown_lower_bound,
    times_shown_upper_bound
FROM filtered
WHERE rn = 1                       -- one record per creative
ORDER BY last_shown DESC NULLS LAST
LIMIT 5;