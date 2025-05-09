WITH pop AS (   /* annual population (ACS 5‑yr) + previous year */
    SELECT
        t."GEO_ID"                                            AS "ZIP_GEO_ID",
        DATE_PART('YEAR', t."DATE")                           AS "YEAR",
        t."VALUE"                                             AS "POP",
        LAG(t."VALUE") OVER (PARTITION BY t."GEO_ID"
                             ORDER BY DATE_PART('YEAR', t."DATE")) AS "POP_PREV"
    FROM "GLOBAL_GOVERNMENT"."CYBERSYN"."AMERICAN_COMMUNITY_SURVEY_TIMESERIES" t
    WHERE t."VARIABLE" = 'B01003_001E_5YR'          -- total population, 5‑yr estimate
      AND t."GEO_ID" LIKE 'zip/%'                   -- restrict to ZIP Code Tabulation Areas
      AND t."DATE" BETWEEN '2014-12-31' AND '2020-12-31'
),
growth AS (     /* growth rate, keep ZIP‑years with ≥25 000 pop */
    SELECT
        p."ZIP_GEO_ID",
        p."YEAR",
        100.0 * (p."POP" - p."POP_PREV") / NULLIF(p."POP_PREV", 0) AS "GROWTH_PCT"
    FROM pop p
    WHERE p."YEAR" BETWEEN 2015 AND 2020
      AND p."POP" >= 25000
      AND p."POP_PREV" IS NOT NULL
),
state_map AS (  /* map each ZIP to two‑letter state abbreviation */
    SELECT
        r."RELATED_GEO_ID" AS "ZIP_GEO_ID",
        COALESCE(
            SPLIT_PART(g."ISO_3166_2_CODE", '-', 2),
            CASE RIGHT(g."GEO_ID", 2)
                WHEN '01' THEN 'AL' WHEN '02' THEN 'AK' WHEN '04' THEN 'AZ'
                WHEN '05' THEN 'AR' WHEN '06' THEN 'CA' WHEN '08' THEN 'CO'
                WHEN '09' THEN 'CT' WHEN '10' THEN 'DE' WHEN '11' THEN 'DC'
                WHEN '12' THEN 'FL' WHEN '13' THEN 'GA' WHEN '15' THEN 'HI'
                WHEN '16' THEN 'ID' WHEN '17' THEN 'IL' WHEN '18' THEN 'IN'
                WHEN '19' THEN 'IA' WHEN '20' THEN 'KS' WHEN '21' THEN 'KY'
                WHEN '22' THEN 'LA' WHEN '23' THEN 'ME' WHEN '24' THEN 'MD'
                WHEN '25' THEN 'MA' WHEN '26' THEN 'MI' WHEN '27' THEN 'MN'
                WHEN '28' THEN 'MS' WHEN '29' THEN 'MO' WHEN '30' THEN 'MT'
                WHEN '31' THEN 'NE' WHEN '32' THEN 'NV' WHEN '33' THEN 'NH'
                WHEN '34' THEN 'NJ' WHEN '35' THEN 'NM' WHEN '36' THEN 'NY'
                WHEN '37' THEN 'NC' WHEN '38' THEN 'ND' WHEN '39' THEN 'OH'
                WHEN '40' THEN 'OK' WHEN '41' THEN 'OR' WHEN '42' THEN 'PA'
                WHEN '44' THEN 'RI' WHEN '45' THEN 'SC' WHEN '46' THEN 'SD'
                WHEN '47' THEN 'TN' WHEN '48' THEN 'TX' WHEN '49' THEN 'UT'
                WHEN '50' THEN 'VT' WHEN '51' THEN 'VA' WHEN '53' THEN 'WA'
                WHEN '54' THEN 'WV' WHEN '55' THEN 'WI' WHEN '56' THEN 'WY'
            END
        ) AS "STATE_ABBR"
    FROM "GLOBAL_GOVERNMENT"."CYBERSYN"."GEOGRAPHY_RELATIONSHIPS" r
    JOIN "GLOBAL_GOVERNMENT"."CYBERSYN"."GEOGRAPHY_INDEX" g
      ON g."GEO_ID" = r."GEO_ID"
    WHERE r."LEVEL" = 'State'
      AND r."RELATED_LEVEL" = 'CensusZipCodeTabulationArea'
),
ranked AS (     /* rank ZIPs by growth rate within each calendar year */
    SELECT
        g."YEAR",
        g."ZIP_GEO_ID",
        g."GROWTH_PCT",
        ROW_NUMBER() OVER (PARTITION BY g."YEAR"
                           ORDER BY g."GROWTH_PCT" DESC NULLS LAST) AS "RN"
    FROM growth g
)
SELECT
    REPLACE(r."ZIP_GEO_ID", 'zip/', '') AS "zip_code",
    sm."STATE_ABBR"                     AS "state_abbreviation",
    r."YEAR"                            AS "year",
    ROUND(r."GROWTH_PCT", 4)            AS "annual_growth_rate_percentage"
FROM ranked r
LEFT JOIN state_map sm
       ON sm."ZIP_GEO_ID" = r."ZIP_GEO_ID"
WHERE r."RN" = 2
ORDER BY r."YEAR";