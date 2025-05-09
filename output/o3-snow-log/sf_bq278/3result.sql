/*  State-level solar-potential comparison at Postal-Code vs. Census-Tract granularity  */
WITH agg_postal AS (   -- aggregate ZIP-code level
    SELECT
        "state_name",
        'postal_code'::TEXT                                              AS "level",
        SUM("count_qualified")                                           AS "total_qualified_buildings",
        AVG("percent_covered")                                           AS "avg_percent_covered",
        AVG("percent_qualified")                                         AS "avg_percent_qualified",
        SUM("number_of_panels_total")                                    AS "total_potential_panels",
        SUM("kw_total")                                                  AS "total_kw_capacity",
        SUM("yearly_sunlight_kwh_total")                                 AS "total_energy_potential_kwh",
        SUM("carbon_offset_metric_tons")                                 AS "total_carbon_offset_metric_tons",
        SUM("existing_installs_count")                                   AS "current_installations"
    FROM SUNROOF_SOLAR.SUNROOF_SOLAR.SOLAR_POTENTIAL_BY_POSTAL_CODE
    GROUP BY "state_name"
),

calc_postal AS (
    SELECT
        *,
        ROUND(            /* gap = adjusted potential installs – existing installs */
            ("total_qualified_buildings"
             * ("avg_percent_covered"/100)
             * ("avg_percent_qualified"/100))
          - "current_installations", 4)                                  AS "potential_installations_gap"
    FROM agg_postal
),

agg_tract AS (   -- aggregate Census-tract level
    SELECT
        "state_name",
        'census_tract'::TEXT                                             AS "level",
        SUM("count_qualified")                                           AS "total_qualified_buildings",
        AVG("percent_covered")                                           AS "avg_percent_covered",
        AVG("percent_qualified")                                         AS "avg_percent_qualified",
        SUM("number_of_panels_total")                                    AS "total_potential_panels",
        SUM("kw_total")                                                  AS "total_kw_capacity",
        SUM("yearly_sunlight_kwh_total")                                 AS "total_energy_potential_kwh",
        SUM("carbon_offset_metric_tons")                                 AS "total_carbon_offset_metric_tons",
        SUM("existing_installs_count")                                   AS "current_installations"
    FROM SUNROOF_SOLAR.SUNROOF_SOLAR.SOLAR_POTENTIAL_BY_CENSUSTRACT
    GROUP BY "state_name"
),

calc_tract AS (
    SELECT
        *,
        ROUND(
            ("total_qualified_buildings"
             * ("avg_percent_covered"/100)
             * ("avg_percent_qualified"/100))
          - "current_installations", 4)                                  AS "potential_installations_gap"
    FROM agg_tract
)

SELECT
    "state_name",
    "level",
    "total_qualified_buildings",
    ROUND("avg_percent_covered",     4) AS "avg_percent_covered",
    ROUND("avg_percent_qualified",   4) AS "avg_percent_qualified",
    "total_potential_panels",
    "total_kw_capacity",
    "total_energy_potential_kwh",
    "total_carbon_offset_metric_tons",
    "current_installations",
    "potential_installations_gap"
FROM (
    SELECT * FROM calc_postal
    UNION ALL
    SELECT * FROM calc_tract
)
ORDER BY "state_name" ASC, "level" ASC;