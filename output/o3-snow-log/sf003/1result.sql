/*  Second-highest annual population growth (≥ 25 k pop) by ZIP, 2015-2020  */

WITH population AS (   -- 5-Year ACS total-population estimates by ZIP
    SELECT
        "GEO_ID"                       AS zip_geo_id ,          -- e.g. zip/30301
        YEAR("DATE")                  AS yr ,
        "VALUE"::FLOAT               AS pop
    FROM GLOBAL_GOVERNMENT.CYBERSYN.AMERICAN_COMMUNITY_SURVEY_TIMESERIES
    WHERE "VARIABLE" = 'B01003_001E_5YR'
      AND "GEO_ID"  LIKE 'zip/%'
      AND YEAR("DATE") BETWEEN 2014 AND 2020            -- need t and t-1
),

growth AS (          -- compute year-over-year % growth
    SELECT
        cur.zip_geo_id ,
        cur.yr                                           AS year ,
        cur.pop                                          AS pop_curr ,
        prv.pop                                          AS pop_prev ,
        /* growth % = (Pop_t – Pop_{t-1}) / Pop_{t-1} * 100 */
        (cur.pop - prv.pop) / prv.pop * 100              AS growth_pct
    FROM population cur
    JOIN population  prv
      ON prv.zip_geo_id = cur.zip_geo_id
     AND prv.yr        = cur.yr - 1                      -- previous year
    WHERE cur.yr BETWEEN 2015 AND 2020                  -- final output years
      AND cur.pop >= 25000                              -- ≥ 25 k pop (current yr)
),

/* Map ZIPs to their parent State to get the postal abbreviation */
state_lookup AS (
    SELECT
        rel."RELATED_GEO_ID"          AS zip_geo_id ,     -- child (ZIP)
        rel."GEO_ID"                  AS state_geo_id
    FROM GLOBAL_GOVERNMENT.CYBERSYN.GEOGRAPHY_RELATIONSHIPS rel
    WHERE rel."LEVEL"         = 'State'
      AND rel."RELATED_LEVEL" = 'CensusZipCodeTabulationArea'
      AND rel."RELATIONSHIP_TYPE" IN ('Contains','Overlaps')
),

state_abbr AS (
    SELECT
        sl.zip_geo_id ,
        REGEXP_REPLACE(idx."ISO_3166_2_CODE", 'US-', '') AS state_abbr  -- e.g. US-CA → CA
    FROM state_lookup                    sl
    JOIN GLOBAL_GOVERNMENT.CYBERSYN.GEOGRAPHY_INDEX idx
      ON idx."GEO_ID" = sl.state_geo_id
),

ranked AS (          -- rank ZIPs by growth each year
    SELECT
        g.year ,
        g.zip_geo_id ,
        sa.state_abbr ,
        g.growth_pct ,
        ROW_NUMBER() OVER (PARTITION BY g.year
                           ORDER BY g.growth_pct DESC NULLS LAST) AS rn
    FROM growth      g
    LEFT JOIN state_abbr sa
           ON sa.zip_geo_id = g.zip_geo_id
)

SELECT
    year                                              AS "YEAR" ,
    REGEXP_REPLACE(zip_geo_id,'zip/','')              AS "ZIP_CODE" ,
    state_abbr                                        AS "STATE" ,
    ROUND(growth_pct,4)                               AS "ANNUAL_GROWTH_RATE_PCT"
FROM ranked
WHERE rn = 2                         -- 2ᵈ-highest growth per year
ORDER BY year;