/*  Aggregate postal-code-level metrics per state  */
WITH postal AS (
    SELECT
        'postal_code'                                       AS "level",
        "state_name",
        /* buildings already deemed suitable for solar */
        SUM("count_qualified")                              AS "total_qualified_buildings",
        /* Google-Maps coverage & suitability (averaged)  */
        ROUND(AVG("percent_covered"),   4)                  AS "avg_percent_covered",
        ROUND(AVG("percent_qualified"), 4)                  AS "avg_percent_qualified",
        /* physical and electrical potential */
        SUM("number_of_panels_total")                       AS "total_potential_panels",
        SUM("kw_total")                                     AS "total_kw_capacity",
        SUM("yearly_sunlight_kwh_total")                    AS "total_energy_kwh",
        SUM("carbon_offset_metric_tons")                    AS "total_carbon_offset_tons",
        /* currently installed buildings */
        SUM("existing_installs_count")                      AS "current_installs",
        /* estimated total buildings = qualified ÷ suitability ÷ coverage */
        ROUND(
            SUM(
                ("count_qualified" * 100 * 100)
                / NULLIF("percent_qualified",0)
                / NULLIF("percent_covered" ,0)
            ),
            0
        )                                                   AS "adjusted_potential_buildings",
        /* installation gap = potential – current installs */
        ROUND(
            SUM(
                ("count_qualified" * 100 * 100)
                / NULLIF("percent_qualified",0)
                / NULLIF("percent_covered" ,0)
            )
            - SUM("existing_installs_count"),
            0
        )                                                   AS "gap_potential_installations"
    FROM SUNROOF_SOLAR.SUNROOF_SOLAR.SOLAR_POTENTIAL_BY_POSTAL_CODE
    GROUP BY "state_name"
),

/*  Aggregate census-tract-level metrics per state  */
tract AS (
    SELECT
        'census_tract'                                      AS "level",
        "state_name",
        SUM("count_qualified")                              AS "total_qualified_buildings",
        ROUND(AVG("percent_covered"),   4)                  AS "avg_percent_covered",
        ROUND(AVG("percent_qualified"), 4)                  AS "avg_percent_qualified",
        SUM("number_of_panels_total")                       AS "total_potential_panels",
        SUM("kw_total")                                     AS "total_kw_capacity",
        SUM("yearly_sunlight_kwh_total")                    AS "total_energy_kwh",
        SUM("carbon_offset_metric_tons")                    AS "total_carbon_offset_tons",
        SUM("existing_installs_count")                      AS "current_installs",
        ROUND(
            SUM(
                ("count_qualified" * 100 * 100)
                / NULLIF("percent_qualified",0)
                / NULLIF("percent_covered" ,0)
            ),
            0
        )                                                   AS "adjusted_potential_buildings",
        ROUND(
            SUM(
                ("count_qualified" * 100 * 100)
                / NULLIF("percent_qualified",0)
                / NULLIF("percent_covered" ,0)
            )
            - SUM("existing_installs_count"),
            0
        )                                                   AS "gap_potential_installations"
    FROM SUNROOF_SOLAR.SUNROOF_SOLAR.SOLAR_POTENTIAL_BY_CENSUSTRACT
    GROUP BY "state_name"
)

/*  Combine both granularities and present side-by-side  */
SELECT *
FROM postal
UNION ALL
SELECT *
FROM tract
ORDER BY "state_name", "level" NULLS LAST;