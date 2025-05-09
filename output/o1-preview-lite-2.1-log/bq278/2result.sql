SELECT
  state_name AS State_Name,
  Level,
  SUM(count_qualified) AS Number_of_Buildings_Available,
  ROUND(SUM(percent_covered * count_qualified) / SUM(count_qualified), 4) AS Percentage_Covered_by_Sunroof,
  ROUND(SUM(percent_qualified * count_qualified) / SUM(count_qualified), 4) AS Percentage_Suitable_for_Solar,
  SUM(number_of_panels_total) AS Total_Potential_Panel_Count,
  ROUND(SUM(kw_total), 4) AS Total_Kilowatt_Capacity,
  ROUND(SUM(yearly_sunlight_kwh_total), 4) AS Energy_Generation_Potential,
  ROUND(SUM(carbon_offset_metric_tons), 4) AS Carbon_Dioxide_Offset,
  SUM(count_qualified - existing_installs_count) AS Gap_in_Potential_Installations
FROM (
  SELECT 
    `state_name`,
    'Postal_Code' AS Level,
    `count_qualified`,
    `percent_covered`,
    `percent_qualified`,
    `number_of_panels_total`,
    `kw_total`,
    `yearly_sunlight_kwh_total`,
    `carbon_offset_metric_tons`,
    `existing_installs_count`
  FROM `bigquery-public-data.sunroof_solar.solar_potential_by_postal_code`
  UNION ALL
  SELECT 
    `state_name`,
    'Census_Tract' AS Level,
    `count_qualified`,
    `percent_covered`,
    `percent_qualified`,
    `number_of_panels_total`,
    `kw_total`,
    `yearly_sunlight_kwh_total`,
    `carbon_offset_metric_tons`,
    `existing_installs_count`
  FROM `bigquery-public-data.sunroof_solar.solar_potential_by_censustract`
) AS combined_data
GROUP BY state_name, Level
ORDER BY state_name, Level;