WITH tract_level AS (   -- build tract‑level records that have both 2015 & 2018 median‑income values
    SELECT
        SUBSTR(t17."geo_id", 1, 2)                              AS state_fips ,
        GREATEST( COALESCE(t17."unemployed_pop",0)
                + COALESCE(t17."not_in_labor_force",0)
                - COALESCE(t17."group_quarters",0) , 0)          AS adjusted_nlf ,
        (  COALESCE(t18."median_income",NULL)
         - COALESCE(t15."median_income",NULL) )                  AS income_diff ,
        COALESCE(t17."total_pop",0)                              AS total_pop ,
        CASE WHEN COALESCE(t17."total_pop",0) > 0 THEN
                 GREATEST( COALESCE(t17."unemployed_pop",0)
                         + COALESCE(t17."not_in_labor_force",0)
                         - COALESCE(t17."group_quarters",0) , 0)
                 / t17."total_pop"
        END                                                      AS prop_adj_nlf
    FROM  "CENSUS_BUREAU_ACS_2"."CENSUS_BUREAU_ACS"."CENSUSTRACT_2017_5YR"  t17
    JOIN  "CENSUS_BUREAU_ACS_2"."CENSUS_BUREAU_ACS"."CENSUSTRACT_2015_5YR"  t15
        ON  t17."geo_id" = t15."geo_id"
    JOIN  "CENSUS_BUREAU_ACS_2"."CENSUS_BUREAU_ACS"."CENSUSTRACT_2018_5YR"  t18
        ON  t17."geo_id" = t18."geo_id"
    WHERE  t15."median_income" IS NOT NULL
      AND  t18."median_income" IS NOT NULL
),
state_agg AS (          -- aggregate to the state level
    SELECT
        state_fips ,
        SUM(income_diff)                     AS total_income_change ,
        SUM(adjusted_nlf)                    AS total_adjusted_nlf ,
        AVG(prop_adj_nlf)                    AS avg_prop_adj_nlf
    FROM   tract_level
    GROUP  BY state_fips
)
SELECT
    st."state"                        AS state_abbr ,
    sa.total_income_change            ,
    sa.total_adjusted_nlf             ,
    sa.avg_prop_adj_nlf
FROM   state_agg          sa
JOIN   "CENSUS_BUREAU_ACS_2"."GEO_US_BOUNDARIES"."STATES"  st
       ON st."state_fips_code" = sa.state_fips
ORDER  BY sa.total_adjusted_nlf  ASC,
          st."state"              ASC
LIMIT 3;