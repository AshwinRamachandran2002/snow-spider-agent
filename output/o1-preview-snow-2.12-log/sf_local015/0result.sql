SELECT
  "Helmet_Status",
  ROUND((COUNT(*) * 100.0) / SUM(COUNT(*)) OVER(), 4) AS "Percentage"
FROM (
  SELECT
    CASE
      WHEN LOWER(TRIM(COALESCE(v."victim_safety_equipment_1", ''))) LIKE '%motorcycle helmet used%' THEN 'Wearing_Helmet'
      WHEN LOWER(TRIM(COALESCE(v."victim_safety_equipment_1", ''))) LIKE '%motorcycle helmet not used%' THEN 'Not_Wearing_Helmet'
      ELSE 'Unknown'
    END AS "Helmet_Status"
  FROM
    "CALIFORNIA_TRAFFIC_COLLISION"."CALIFORNIA_TRAFFIC_COLLISION"."VICTIMS" v
  JOIN
    "CALIFORNIA_TRAFFIC_COLLISION"."CALIFORNIA_TRAFFIC_COLLISION"."PARTIES" p
    ON v."case_id" = p."case_id" AND v."party_number" = p."party_number"
  WHERE
    (
      LOWER(COALESCE(p."statewide_vehicle_type", '')) LIKE '%motorcycle%'
      OR LOWER(COALESCE(p."statewide_vehicle_type", '')) LIKE '%scooter%'
      OR LOWER(COALESCE(p."statewide_vehicle_type", '')) LIKE '%moped%'
    )
    AND LOWER(TRIM(COALESCE(v."victim_degree_of_injury", ''))) = 'killed'
) t
GROUP BY
  "Helmet_Status";