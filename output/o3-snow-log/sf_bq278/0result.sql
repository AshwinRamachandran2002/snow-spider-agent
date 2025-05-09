/*  State-level comparison of solar potential
    – one row per state for Postal-Code aggregation
    – one row per state for Census-Tract aggregation                                    */

WITH postal_code_agg AS (
    SELECT
        "state_name",
        'POSTAL_CODE'                                                  AS "aggregation_level",
        SUM("count_qualified")                                         AS "total_qualified_buildings",
        AVG("percent_covered")                                         AS "avg_percent_covered",
        AVG("percent_qualified")                                       AS "avg_percent_qualified",
        SUM("number_of_panels_total")                                  AS "total_potential_panels",
        SUM("kw_total")                                                AS "total_kw_capacity",
        SUM("yearly_sunlight_kwh_total")                               AS "total_energy_kwh",
        SUM("carbon_offset_metric_tons")                               AS "total_carbon_offset",
        SUM("existing_installs_count")                                 AS "current_installs",
        /* gap = scale qualified buildings up to statewide level using
                 coverage & suitability percentages, then subtract current installs */
        CASE
            WHEN AVG("percent_covered") = 0 OR AVG("percent_qualified") = 0 THEN NULL
            ELSE  ( SUM("count_qualified")
                   / ( (AVG("percent_covered")   / 100)
                     * (AVG("percent_qualified") / 100) )
                  ) - SUM("existing_installs_count")
        END                                                            AS "potential_installation_gap"
    FROM SUNROOF_SOLAR.SUNROOF_SOLAR.SOLAR_POTENTIAL_BY_POSTAL_CODE
    GROUP BY "state_name"
),

census_tract_agg AS (
    SELECT
        "state_name",
        'CENSUS_TRACT'                                                 AS "aggregation_level",
        SUM("count_qualified")                                         AS "total_qualified_buildings",
        AVG("percent_covered")                                         AS "avg_percent_covered",
        AVG("percent_qualified")                                       AS "avg_percent_qualified",
        SUM("number_of_panels_total")                                  AS "total_potential_panels",
        SUM("kw_total")                                                AS "total_kw_capacity",
        SUM("yearly_sunlight_kwh_total")                               AS "total_energy_kwh",
        SUM("carbon_offset_metric_tons")                               AS "total_carbon_offset",
        SUM("existing_installs_count")                                 AS "current_installs",
        CASE
            WHEN AVG("percent_covered") = 0 OR AVG("percent_qualified") = 0 THEN NULL
            ELSE  ( SUM("count_qualified")
                   / ( (AVG("percent_covered")   / 100)
                     * (AVG("percent_qualified") / 100) )
                  ) - SUM("existing_installs_count")
        END                                                            AS "potential_installation_gap"
    FROM SUNROOF_SOLAR.SUNROOF_SOLAR.SOLAR_POTENTIAL_BY_CENSUSTRACT
    GROUP BY "state_name"
)

SELECT *
FROM (
    SELECT * FROM postal_code_agg
    UNION ALL
    SELECT * FROM census_tract_agg
)
ORDER BY "state_name", "aggregation_level";