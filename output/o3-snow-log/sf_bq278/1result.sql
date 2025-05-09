WITH postal_level AS (
    SELECT
        "state_name"                                            AS state_name,
        'POSTAL_CODE'                                           AS region_level,
        SUM("count_qualified")                                  AS total_buildings_available,
        AVG("percent_covered")                                  AS avg_percent_covered,
        AVG("percent_qualified")                                AS avg_percent_qualified,
        SUM("number_of_panels_total")                           AS total_potential_panel_count,
        SUM("kw_total")                                         AS total_kw_capacity,
        SUM("yearly_sunlight_kwh_total")                        AS total_energy_generation_potential,
        SUM("carbon_offset_metric_tons")                        AS total_carbon_dioxide_offset,
        SUM("existing_installs_count")                          AS current_buildings_with_solar,
        /*  Gap = (qualified ÷ (percent_covered/100)) – current installs            */
        SUM( ("count_qualified") / NULLIF("percent_covered",0) * 100 )   
          - SUM("existing_installs_count")                      AS potential_installation_gap
    FROM  "SUNROOF_SOLAR"."SUNROOF_SOLAR"."SOLAR_POTENTIAL_BY_POSTAL_CODE"
    GROUP BY "state_name"
), 
tract_level AS (
    SELECT
        "state_name"                                            AS state_name,
        'CENSUS_TRACT'                                          AS region_level,
        SUM("count_qualified")                                  AS total_buildings_available,
        AVG("percent_covered")                                  AS avg_percent_covered,
        AVG("percent_qualified")                                AS avg_percent_qualified,
        SUM("number_of_panels_total")                           AS total_potential_panel_count,
        SUM("kw_total")                                         AS total_kw_capacity,
        SUM("yearly_sunlight_kwh_total")                        AS total_energy_generation_potential,
        SUM("carbon_offset_metric_tons")                        AS total_carbon_dioxide_offset,
        SUM("existing_installs_count")                          AS current_buildings_with_solar,
        /*  Gap = (qualified ÷ (percent_covered/100)) – current installs            */
        SUM( ("count_qualified") / NULLIF("percent_covered",0) * 100 )   
          - SUM("existing_installs_count")                      AS potential_installation_gap
    FROM  "SUNROOF_SOLAR"."SUNROOF_SOLAR"."SOLAR_POTENTIAL_BY_CENSUSTRACT"
    GROUP BY "state_name"
)

SELECT *
FROM   postal_level
UNION ALL
SELECT *
FROM   tract_level
ORDER  BY state_name,
         region_level;