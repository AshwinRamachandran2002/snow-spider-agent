WITH postal AS (
    SELECT
        'postal_code'                          AS "level_type",
        "state_name",
        /*  buildings already determined to be suitable for solar                   */
        SUM("count_qualified")                 AS "total_buildings_available",
        /*  average share of all map-visible buildings that were analysed           */
        AVG("percent_covered")                 AS "avg_percent_covered",
        /*  average share of analysed buildings that are suitable for solar         */
        AVG("percent_qualified")               AS "avg_percent_qualified",
        /*  technical potential metrics                                             */
        SUM("number_of_panels_total")          AS "total_potential_panel_count",
        SUM("kw_total")                        AS "total_kw_capacity",
        SUM("yearly_sunlight_kwh_total")       AS "total_energy_generation_kwh",
        SUM("carbon_offset_metric_tons")       AS "total_carbon_offset_metric_tons",
        /*  existing installations                                                  */
        SUM("existing_installs_count")         AS "current_installations",
        /*  potential gap = estimated total suitable buildings – existing installs  */
        SUM(
            CASE
                WHEN "percent_qualified" <> 0 AND "percent_covered" <> 0 THEN
                     "count_qualified"
                     / ("percent_qualified" / 100)   -- back-out suitability %
                     / ("percent_covered"   / 100)   -- back-out coverage %
                ELSE 0
            END
        ) - SUM("existing_installs_count")     AS "gap_potential_installations"
    FROM SUNROOF_SOLAR.SUNROOF_SOLAR.SOLAR_POTENTIAL_BY_POSTAL_CODE
    GROUP BY "state_name"
), tract AS (
    SELECT
        'census_tract'                         AS "level_type",
        "state_name",
        SUM("count_qualified")                 AS "total_buildings_available",
        AVG("percent_covered")                 AS "avg_percent_covered",
        AVG("percent_qualified")               AS "avg_percent_qualified",
        SUM("number_of_panels_total")          AS "total_potential_panel_count",
        SUM("kw_total")                        AS "total_kw_capacity",
        SUM("yearly_sunlight_kwh_total")       AS "total_energy_generation_kwh",
        SUM("carbon_offset_metric_tons")       AS "total_carbon_offset_metric_tons",
        SUM("existing_installs_count")         AS "current_installations",
        SUM(
            CASE
                WHEN "percent_qualified" <> 0 AND "percent_covered" <> 0 THEN
                     "count_qualified"
                     / ("percent_qualified" / 100)
                     / ("percent_covered"   / 100)
                ELSE 0
            END
        ) - SUM("existing_installs_count")     AS "gap_potential_installations"
    FROM SUNROOF_SOLAR.SUNROOF_SOLAR.SOLAR_POTENTIAL_BY_CENSUSTRACT
    GROUP BY "state_name"
)
SELECT *
FROM   postal
UNION ALL
SELECT *
FROM   tract
ORDER  BY "state_name" NULLS LAST,
          "level_type";