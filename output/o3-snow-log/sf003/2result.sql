/*--------------------------------------------------------------
  For each calendar-year 2015-2020:
    • compute annual population-growth rates for every Census
      ZIP Code (5-Year ACS total-population estimates)
    • keep ZIPs with ≥25 000 residents in the given year
    • rank growth rates per year and keep the second-highest
    • append the two-letter state abbreviation
----------------------------------------------------------------*/
WITH pop AS (   /* pull 2014-2020 ZIP-level population series */
    SELECT  "GEO_ID",
            "DATE",
            "VALUE",
            LAG("VALUE") OVER (PARTITION BY "GEO_ID"
                               ORDER BY "DATE")        AS "PREV_VALUE"
    FROM    GLOBAL_GOVERNMENT.CYBERSYN.AMERICAN_COMMUNITY_SURVEY_TIMESERIES
    WHERE   "VARIABLE" = 'B01003_001E_5YR'             -- Total population
      AND   "DATE" BETWEEN '2014-12-31' AND '2020-12-31'
      AND   "GEO_ID" ILIKE 'zip/%'
), rates AS (   /* year-over-year growth percentages */
    SELECT  "GEO_ID",
            TO_CHAR("DATE",'YYYY')                     AS "YEAR",
            ("VALUE" - "PREV_VALUE")
            / NULLIF("PREV_VALUE",0) * 100            AS "GROWTH_PCT",
            "VALUE"                                   AS "POP"
    FROM    pop
    WHERE   "PREV_VALUE" IS NOT NULL                  -- ensure prior year
), filtered AS ( /* keep ZIP-years with pop ≥25k and years 2015-2020 */
    SELECT  *
    FROM    rates
    WHERE   "POP"  >= 25000
      AND   "YEAR" BETWEEN '2015' AND '2020'
), ranked AS (   /* rank growth rates within each year */
    SELECT  *,
            ROW_NUMBER() OVER (PARTITION BY "YEAR"
                               ORDER BY "GROWTH_PCT" DESC NULLS LAST) AS rn
    FROM    filtered
), second_best AS ( /* grab 2nd-highest growth ZIP each year */
    SELECT  "YEAR",
            "GEO_ID",
            ROUND("GROWTH_PCT",2) AS "GROWTH_RATE_PCT"
    FROM    ranked
    WHERE   rn = 2
), zip_state AS ( /* map ZIPs to their State GEO_IDs */
    SELECT DISTINCT
           gr."GEO_ID"           AS "ZIP_GEO_ID",
           gr."RELATED_GEO_ID"   AS "STATE_GEO_ID"
    FROM   GLOBAL_GOVERNMENT.CYBERSYN.GEOGRAPHY_RELATIONSHIPS gr
    WHERE  gr."RELATED_LEVEL" = 'State'
      AND  gr."GEO_ID" ILIKE 'zip/%'
), state_abbr AS ( /* derive two-letter state abbreviations */
    SELECT  "GEO_ID",
            SPLIT_PART("ISO_3166_2_CODE",'-',2) AS "STATE_ABBR"
    FROM    GLOBAL_GOVERNMENT.CYBERSYN.GEOGRAPHY_INDEX
    WHERE   "LEVEL" = 'State'
)
SELECT  sb."YEAR",
        SPLIT_PART(sb."GEO_ID",'/',2)      AS "ZIP_CODE",
        sa."STATE_ABBR",
        sb."GROWTH_RATE_PCT"
FROM    second_best  sb
LEFT JOIN zip_state  zs ON sb."GEO_ID"       = zs."ZIP_GEO_ID"
LEFT JOIN state_abbr sa ON zs."STATE_GEO_ID" = sa."GEO_ID"
ORDER BY sb."YEAR";