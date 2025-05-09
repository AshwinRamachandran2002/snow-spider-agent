SELECT
  state_name AS State_Name,
  'Postal_Code' AS Level,
  SUM(count_qualified) AS Number_of_Buildings_Available,
  ROUND(AVG(percent_covered), 4) AS Percentage_Covered_by_Sunroof,
  ROUND(AVG(percent_qualified), 4) AS Percentage_Suitable_for_Solar,
  SUM(number_of_panels_total) AS Total_Potential_Panel_Count,
  ROUND(SUM(kw_total), 4) AS Total_Kilowatt_Capacity,
  ROUND(SUM(yearly_sunlight_kwh_total), 4) AS Energy_Generation_Potential,
  ROUND(SUM(carbon_offset_metric_tons), 4) AS Carbon_Dioxide_Offset,
  SUM(count_qualified) - SUM(existing_installs_count) AS Gap_in_Potential_Installations
FROM `bigquery-public-data.sunroof_solar.solar_potential_by_postal_code`
GROUP BY state_name

UNION ALL

SELECT
  state_name AS State_Name,
  'Census_Tract' AS Level,
  SUM(count_qualified) AS Number_of_Buildings_Available,
  ROUND(AVG(percent_covered), 4) AS Percentage_Covered_by_Sunroof,
  ROUND(AVG(percent_qualified), 4) AS Percentage_Suitable_for_Solar,
  SUM(number_of_panels_total) AS Total_Potential_Panel_Count,
  ROUND(SUM(kw_total), 4) AS Total_Kilowatt_Capacity,
  ROUND(SUM(yearly_sunlight_kwh_total), 4) AS Energy_Generation_Potential,
  ROUND(SUM(carbon_offset_metric_tons), 4) AS Carbon_Dioxide_Offset,
  SUM(count_qualified) - SUM(existing_installs_count) AS Gap_in_Potential_Installations
FROM `bigquery-public-data.sunroof_solar.solar_potential_by_censustract`
GROUP BY state_name;