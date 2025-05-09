/* -----------------------------------------------------------
   Solar-potential comparison by STATE & GEOGRAPHIC LEVEL
   -----------------------------------------------------------
   For each state two rows are returned:
      – geo_level = 'POSTAL_CODE'
      – geo_level = 'CENSUS_TRACT'

   gap calculation
   ----------------
   potential_total_buildings_per_record =
         (count_qualified * 10000) / (percent_covered * percent_qualified)

   gap = Σ(potential_total_buildings_per_record) – Σ(existing_installs_count)

   All other figures are simple SUM or AVG aggregates as requested.
-------------------------------------------------------------*/

WITH postal_state AS (
    SELECT
        "state_name",
        'POSTAL_CODE'                                              AS "geo_level",
        SUM("count_qualified")                                     AS "total_qualified_buildings",
        AVG("percent_covered")                                     AS "avg_percent_covered",
        AVG("percent_qualified")                                   AS "avg_percent_qualified",
        SUM("number_of_panels_total")                              AS "total_panel_count",
        SUM("kw_total")                                            AS "total_kw_capacity_kw",
        SUM("yearly_sunlight_kwh_total")                           AS "total_energy_generation_kwh",
        SUM("carbon_offset_metric_tons")                           AS "total_carbon_offset_metric_tons",
        SUM("existing_installs_count")                             AS "existing_installations",
        /* potential installations gap */
        SUM( ("count_qualified" * 10000)
             / NULLIF("percent_covered" * "percent_qualified", 0) ) 
          - SUM("existing_installs_count")                         AS "potential_install_gap"
    FROM SUNROOF_SOLAR.SUNROOF_SOLAR.SOLAR_POTENTIAL_BY_POSTAL_CODE
    GROUP BY "state_name"
),
tract_state AS (
    SELECT
        "state_name",
        'CENSUS_TRACT'                                             AS "geo_level",
        SUM("count_qualified")                                     AS "total_qualified_buildings",
        AVG("percent_covered")                                     AS "avg_percent_covered",
        AVG("percent_qualified")                                   AS "avg_percent_qualified",
        SUM("number_of_panels_total")                              AS "total_panel_count",
        SUM("kw_total")                                            AS "total_kw_capacity_kw",
        SUM("yearly_sunlight_kwh_total")                           AS "total_energy_generation_kwh",
        SUM("carbon_offset_metric_tons")                           AS "total_carbon_offset_metric_tons",
        SUM("existing_installs_count")                             AS "existing_installations",
        /* potential installations gap */
        SUM( ("count_qualified" * 10000)
             / NULLIF("percent_covered" * "percent_qualified", 0) ) 
          - SUM("existing_installs_count")                         AS "potential_install_gap"
    FROM SUNROOF_SOLAR.SUNROOF_SOLAR.SOLAR_POTENTIAL_BY_CENSUSTRACT
    GROUP BY "state_name"
)

SELECT *
FROM   postal_state
UNION ALL
SELECT *
FROM   tract_state
ORDER  BY "state_name", "geo_level" NULLS LAST;