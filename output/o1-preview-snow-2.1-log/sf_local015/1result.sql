SELECT
  CASE
    WHEN (v."victim_safety_equipment_1" ILIKE '%motorcycle helmet used%' OR v."victim_safety_equipment_2" ILIKE '%motorcycle helmet used%') THEN 'Wearing_Helmet'
    WHEN (v."victim_safety_equipment_1" ILIKE '%motorcycle helmet not used%' OR v."victim_safety_equipment_2" ILIKE '%motorcycle helmet not used%') THEN 'Not_Wearing_Helmet'
    ELSE 'Unknown'
  END AS "Helmet_Status",
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 4) AS "Percentage"
FROM
  "CALIFORNIA_TRAFFIC_COLLISION"."CALIFORNIA_TRAFFIC_COLLISION"."VICTIMS" v
JOIN
  "CALIFORNIA_TRAFFIC_COLLISION"."CALIFORNIA_TRAFFIC_COLLISION"."PARTIES" p
  ON v."case_id" = p."case_id" AND v."party_number" = p."party_number"
WHERE
  p."statewide_vehicle_type" ILIKE '%motorcycle%'
  AND LOWER(v."victim_degree_of_injury") = 'killed'
  AND LOWER(v."victim_role") = 'driver'
GROUP BY "Helmet_Status";