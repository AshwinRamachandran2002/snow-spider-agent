WITH postal_agg AS (
    SELECT
        "state_name"                                                     AS "state_name",
        'POSTAL_CODE'                                                    AS "geography_level",
        SUM("count_qualified")                                           AS "total_buildings_available",
        AVG("percent_covered")                                           AS "avg_percent_covered",
        AVG("percent_qualified")                                         AS "avg_percent_qualified",
        SUM("number_of_panels_total")                                    AS "total_potential_panel_count",
        SUM("kw_total")                                                  AS "total_kw_capacity",
        SUM("yearly_sunlight_kwh_total")                                 AS "total_kwh_generation_potential",
        SUM("carbon_offset_metric_tons")                                 AS "total_carbon_offset_metric_tons",
        SUM("existing_installs_count")                                   AS "current_buildings_with_solar",
        SUM(
              ("count_qualified" / NULLIF((("percent_covered"/100) * ("percent_qualified"/100)),0))
            - "existing_installs_count"
        )                                                                AS "potential_installation_gap"
    FROM
        "SUNROOF_SOLAR"."SUNROOF_SOLAR"."SOLAR_POTENTIAL_BY_POSTAL_CODE"
    GROUP BY
        "state_name"
),

tract_agg AS (
    SELECT
        "state_name"                                                     AS "state_name",
        'CENSUS_TRACT'                                                   AS "geography_level",
        SUM("count_qualified")                                           AS "total_buildings_available",
        AVG("percent_covered")                                           AS "avg_percent_covered",
        AVG("percent_qualified")                                         AS "avg_percent_qualified",
        SUM("number_of_panels_total")                                    AS "total_potential_panel_count",
        SUM("kw_total")                                                  AS "total_kw_capacity",
        SUM("yearly_sunlight_kwh_total")                                 AS "total_kwh_generation_potential",
        SUM("carbon_offset_metric_tons")                                 AS "total_carbon_offset_metric_tons",
        SUM("existing_installs_count")                                   AS "current_buildings_with_solar",
        SUM(
              ("count_qualified" / NULLIF((("percent_covered"/100) * ("percent_qualified"/100)),0))
            - "existing_installs_count"
        )                                                                AS "potential_installation_gap"
    FROM
        "SUNROOF_SOLAR"."SUNROOF_SOLAR"."SOLAR_POTENTIAL_BY_CENSUSTRACT"
    GROUP BY
        "state_name"
)

SELECT *
FROM   postal_agg
UNION ALL
SELECT *
FROM   tract_agg
ORDER BY "state_name" NULLS LAST, "geography_level" NULLS LAST;