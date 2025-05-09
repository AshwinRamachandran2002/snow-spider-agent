SELECT
  Helmet_Status,
  ROUND((Fatalities / Total_Fatalities) * 100, 4) AS Percentage
FROM (
  SELECT 
    CASE 
      WHEN (COALESCE(v."victim_safety_equipment_1", '') || ' ' || COALESCE(v."victim_safety_equipment_2", '')) ILIKE '%motorcycle helmet used%'
        THEN 'Wearing_Helmet'
      WHEN (COALESCE(v."victim_safety_equipment_1", '') || ' ' || COALESCE(v."victim_safety_equipment_2", '')) ILIKE '%motorcycle helmet not used%'
        THEN 'Not_Wearing_Helmet'
      ELSE 'Unknown'
    END AS Helmet_Status,
    COUNT(*) AS Fatalities,
    SUM(COUNT(*)) OVER () AS Total_Fatalities
  FROM "CALIFORNIA_TRAFFIC_COLLISION"."CALIFORNIA_TRAFFIC_COLLISION"."VICTIMS" v
  JOIN "CALIFORNIA_TRAFFIC_COLLISION"."CALIFORNIA_TRAFFIC_COLLISION"."PARTIES" p
    ON v."case_id" = p."case_id" AND v."party_number" = p."party_number"
  WHERE p."statewide_vehicle_type" = 'motorcycle or scooter'
    AND LOWER(v."victim_degree_of_injury") = 'killed'
  GROUP BY 1
) sub;