/*--------------------------------------------------------------
  Second–highest ZIP-code population growth (ACS 5-Year)  
  for each year 2015-2020 – only ZIPs with ≥25 000 residents.
--------------------------------------------------------------*/
WITH pop AS (   -- 5-Year population by ZIP & year (need 2014-2020 for lag)
    SELECT
        "GEO_ID",
        TO_NUMBER(LEFT("DATE",4))                  AS "YEAR",
        "VALUE"::FLOAT                             AS "POP"
    FROM GLOBAL_GOVERNMENT.CYBERSYN.AMERICAN_COMMUNITY_SURVEY_TIMESERIES
    WHERE "VARIABLE" = 'B01003_001E_5YR'
      AND "GEO_ID"  ILIKE 'zip/%'
      AND "DATE" BETWEEN '2014-12-31' AND '2020-12-31'
),
growth AS (      -- year-over-year growth rate
    SELECT
        p."GEO_ID",
        p."YEAR",
        (p."POP"
         - LAG(p."POP") OVER (PARTITION BY p."GEO_ID" ORDER BY p."YEAR"))
        / NULLIF(LAG(p."POP") OVER (PARTITION BY p."GEO_ID" ORDER BY p."YEAR"),0)
        AS "GROWTH_RT",
        p."POP"
    FROM pop p
),
eligible AS (    -- keep years 2015-2020 where current pop ≥25 000
    SELECT
        g."GEO_ID",
        g."YEAR",
        g."GROWTH_RT"
    FROM growth g
    WHERE g."YEAR" BETWEEN 2015 AND 2020
      AND g."POP"  >= 25000
      AND g."GROWTH_RT" IS NOT NULL
),
ranked AS (      -- rank growth rates each year
    SELECT
        e.*,
        ROW_NUMBER() OVER (PARTITION BY e."YEAR"
                           ORDER BY e."GROWTH_RT" DESC NULLS LAST) AS rn
    FROM eligible e
),
second_place AS ( -- take the 2-nd highest per year
    SELECT
        "YEAR",
        "GEO_ID",
        "GROWTH_RT"
    FROM ranked
    WHERE rn = 2
),
state_map AS (   -- ZIP → 2-letter state code
    SELECT
        gr."GEO_ID"                        AS "ZIP_GEO_ID",
        MIN(gi."ISO_ALPHA2")               AS "STATE_ABBR"
    FROM GLOBAL_GOVERNMENT.CYBERSYN.GEOGRAPHY_RELATIONSHIPS gr
    JOIN GLOBAL_GOVERNMENT.CYBERSYN.GEOGRAPHY_INDEX gi
      ON gi."GEO_ID" = gr."RELATED_GEO_ID"
    WHERE gr."RELATED_LEVEL"    = 'State'
      AND gr."RELATIONSHIP_TYPE" IN ('Contains','Overlaps')
      AND gr."GEO_ID" ILIKE 'zip/%'
    GROUP BY gr."GEO_ID"
)
SELECT
    sp."YEAR",
    SPLIT_PART(sp."GEO_ID",'/',2)          AS "ZIP_CODE",
    sm."STATE_ABBR",
    ROUND(sp."GROWTH_RT"*100,3)            AS "GROWTH_PCT"
FROM second_place sp
LEFT JOIN state_map sm
       ON sp."GEO_ID" = sm."ZIP_GEO_ID"
ORDER BY sp."YEAR";