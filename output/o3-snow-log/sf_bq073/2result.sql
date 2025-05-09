WITH zip_level_vulnerability AS (
    SELECT
        z17."geo_id"                                   AS "zip",
        g."state_name"                                 AS "state_name",
        0.38 * COALESCE(z17."employed_wholesale_trade", 0)  AS "vuln_wholesale",
        0.41 * COALESCE(z17."employed_manufacturing", 0)    AS "vuln_manufacturing"
    FROM
        CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2017_5YR"  z17
    /* keep only ZIP codes that appear in both 2015 & 2018 income tables */
    JOIN
        CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2015_5YR"  z15
          ON z17."geo_id" = z15."geo_id"
    JOIN
        CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2018_5YR"  z18
          ON z17."geo_id" = z18."geo_id"
    /* map ZIP codes to states */
    JOIN
        CENSUS_BUREAU_ACS_2.GEO_US_BOUNDARIES."ZIP_CODES"           g
          ON z17."geo_id" = g."zip_code"
)

SELECT
    "state_name"                                                        AS "state",
    ROUND(SUM("vuln_wholesale"))        AS "vulnerable_wholesale_trade_workers",
    ROUND(SUM("vuln_manufacturing"))    AS "vulnerable_manufacturing_workers",
    ROUND(SUM("vuln_wholesale") + 
          SUM("vuln_manufacturing"))    AS "total_vulnerable_workers"
FROM
    zip_level_vulnerability
GROUP BY
    "state_name"
ORDER BY
    "total_vulnerable_workers" DESC NULLS LAST;