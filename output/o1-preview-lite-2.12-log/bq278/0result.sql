SELECT
  `state_name`,
  'Postal_Code' AS Level,
  SUM(`count_qualified`) AS Number_of_Buildings_Available,
  AVG(`percent_covered`) AS Percentage_Covered_by_Sunroof,
  AVG(`percent_qualified`) AS Percentage_Suitable_for_Solar,
  SUM(`number_of_panels_total`) AS Total_Potential_Panel_Count,
  SUM(`kw_total`) AS Total_Kilowatt_Capacity,
  SUM(`yearly_sunlight_kwh_total`) AS Energy_Generation_Potential,
  SUM(`carbon_offset_metric_tons`) AS Carbon_Dioxide_Offset,
  SUM(`count_qualified` - `existing_installs_count`) AS Gap_in_Potential_Installations
FROM
  `bigquery-public-data.sunroof_solar.solar_potential_by_postal_code`
GROUP BY
  `state_name`

UNION ALL

SELECT
  `state_name`,
  'Census_Tract' AS Level,
  SUM(`count_qualified`) AS Number_of_Buildings_Available,
  AVG(`percent_covered`) AS Percentage_Covered_by_Sunroof,
  AVG(`percent_qualified`) AS Percentage_Suitable_for_Solar,
  SUM(`number_of_panels_total`) AS Total_Potential_Panel_Count,
  SUM(`kw_total`) AS Total_Kilowatt_Capacity,
  SUM(`yearly_sunlight_kwh_total`) AS Energy_Generation_Potential,
  SUM(`carbon_offset_metric_tons`) AS Carbon_Dioxide_Offset,
  SUM(`count_qualified` - `existing_installs_count`) AS Gap_in_Potential_Installations
FROM
  `bigquery-public-data.sunroof_solar.solar_potential_by_censustract`
GROUP BY
  `state_name`;