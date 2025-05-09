SELECT
    "state_name",
    "Level",
    SUM("count_qualified") AS "Number of Buildings Available for Solar Installations",
    ROUND(AVG("percent_covered"), 4) AS "Percentage Covered by Project Sunroof",
    ROUND(AVG("percent_qualified"), 4) AS "Percentage Suitable for Solar",
    SUM("number_of_panels_total") AS "Total Potential Panel Count",
    ROUND(SUM("kw_total"), 4) AS "Total Kilowatt Capacity",
    ROUND(SUM("yearly_sunlight_kwh_total"), 4) AS "Energy Generation Potential",
    ROUND(SUM("carbon_offset_metric_tons"), 4) AS "Carbon Dioxide Offset",
    SUM("count_qualified") - SUM("existing_installs_count") AS "Gap in Potential Installations"
FROM
(
    SELECT
        "state_name",
        'Postal Code' AS "Level",
        "count_qualified",
        "percent_covered",
        "percent_qualified",
        "number_of_panels_total",
        "kw_total",
        "yearly_sunlight_kwh_total",
        "carbon_offset_metric_tons",
        "existing_installs_count"
    FROM
        SUNROOF_SOLAR.SUNROOF_SOLAR.SOLAR_POTENTIAL_BY_POSTAL_CODE
    UNION ALL
    SELECT
        "state_name",
        'Census Tract' AS "Level",
        "count_qualified",
        "percent_covered",
        "percent_qualified",
        "number_of_panels_total",
        "kw_total",
        "yearly_sunlight_kwh_total",
        "carbon_offset_metric_tons",
        "existing_installs_count"
    FROM
        SUNROOF_SOLAR.SUNROOF_SOLAR.SOLAR_POTENTIAL_BY_CENSUSTRACT
) AS combined_data
GROUP BY
    "state_name",
    "Level"
ORDER BY
    "state_name",
    "Level";