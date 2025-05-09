SELECT "state_name" AS "State",
       "Level",
       SUM("count_qualified") AS "Number of Buildings Available for Solar Installations",
       ROUND(AVG("percent_covered"), 4) AS "Percentage Covered by Project Sunroof",
       ROUND(AVG("percent_qualified"), 4) AS "Percentage Suitable for Solar",
       SUM("number_of_panels_total") AS "Total Potential Panel Count",
       SUM("kw_total") AS "Total Kilowatt Capacity",
       SUM("yearly_sunlight_kwh_total") AS "Energy Generation Potential",
       ROUND(SUM("carbon_offset_metric_tons"), 4) AS "Carbon Dioxide Offset",
       SUM("count_qualified") - SUM(COALESCE("existing_installs_count", 0)) AS "Gap in Potential Installations"
FROM (
  SELECT "state_name", "count_qualified", "percent_covered", "percent_qualified", "number_of_panels_total", "kw_total", "yearly_sunlight_kwh_total", "carbon_offset_metric_tons", "existing_installs_count", 'Postal Code' AS "Level"
  FROM SUNROOF_SOLAR.SUNROOF_SOLAR.SOLAR_POTENTIAL_BY_POSTAL_CODE
  UNION ALL
  SELECT "state_name", "count_qualified", "percent_covered", "percent_qualified", "number_of_panels_total", "kw_total", "yearly_sunlight_kwh_total", "carbon_offset_metric_tons", "existing_installs_count", 'Census Tract' AS "Level"
  FROM SUNROOF_SOLAR.SUNROOF_SOLAR.SOLAR_POTENTIAL_BY_CENSUSTRACT
) AS unioned_table
GROUP BY "state_name", "Level"
ORDER BY "state_name", "Level";