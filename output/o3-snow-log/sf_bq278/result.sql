WITH "combined" AS (
    /* --------------  POSTAL CODE LEVEL -------------- */
    SELECT
        'POSTAL_CODE'                               AS "geography_level",
        "state_name",
        "count_qualified",
        "percent_covered",
        "percent_qualified",
        "number_of_panels_total",
        "kw_total",
        "yearly_sunlight_kwh_total",
        "carbon_offset_metric_tons",
        "existing_installs_count"
    FROM SUNROOF_SOLAR.SUNROOF_SOLAR."SOLAR_POTENTIAL_BY_POSTAL_CODE"
    
    UNION ALL
    
    /* --------------  CENSUS-TRACT LEVEL ------------- */
    SELECT
        'CENSUS_TRACT'                              AS "geography_level",
        "state_name",
        "count_qualified",
        "percent_covered",
        "percent_qualified",
        "number_of_panels_total",
        "kw_total",
        "yearly_sunlight_kwh_total",
        "carbon_offset_metric_tons",
        "existing_installs_count"
    FROM SUNROOF_SOLAR.SUNROOF_SOLAR."SOLAR_POTENTIAL_BY_CENSUSTRACT"
)

SELECT
    "state_name",
    "geography_level",
    
    /* --- core building & coverage metrics --- */
    SUM("count_qualified")                         AS "total_qualified_buildings",
    AVG("percent_covered")                         AS "avg_percent_covered",
    AVG("percent_qualified")                       AS "avg_percent_qualified",
    
    /* --- physical solar-resource metrics --- */
    SUM("number_of_panels_total")                  AS "total_panel_count",
    SUM("kw_total")                                AS "total_kw_capacity",
    SUM("yearly_sunlight_kwh_total")               AS "total_energy_kwh",
    SUM("carbon_offset_metric_tons")               AS "total_carbon_offset_metric_tons",
    
    /* --- adoption metrics --- */
    SUM("existing_installs_count")                 AS "current_installations",
    
    /* --- potential gap calculation --- */
    CASE
        WHEN AVG("percent_covered") = 0
          OR AVG("percent_qualified") = 0
        THEN NULL
        ELSE
            /*  Estimate statewide addressable buildings by
                up-scaling the qualified count using coverage & suitability
                then subtract buildings already having solar. */
            ( SUM("count_qualified")
              / (AVG("percent_covered")  / 100.0)
              / (AVG("percent_qualified")/ 100.0)
            ) - SUM("existing_installs_count")
    END                                            AS "gap_potential_installations"

FROM "combined"
GROUP BY
    "state_name",
    "geography_level"
ORDER BY
    "state_name" NULLS LAST,
    "geography_level";