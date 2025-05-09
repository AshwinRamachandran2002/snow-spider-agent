WITH motorcyclist_parties AS (           -- motorcyclists and their helmet use
     SELECT 
         case_id,
         CASE
              /* “helmet” mentioned and NOT followed by “not” → helmet worn */
              WHEN (lower(COALESCE(party_safety_equipment_1,'')) LIKE '%helmet%' 
                    AND lower(party_safety_equipment_1) NOT LIKE '%not%')
                OR (lower(COALESCE(party_safety_equipment_2,'')) LIKE '%helmet%' 
                    AND lower(party_safety_equipment_2) NOT LIKE '%not%')
              THEN 1                       -- helmet used
              ELSE 0                       -- helmet not used / no helmet info
         END AS helmet_used
     FROM parties
     WHERE lower(COALESCE(statewide_vehicle_type,'')) LIKE '%motorcycle%'   -- only motorcyclists
),
collision_helmet_group AS (              -- assign each motorcycle crash a helmet group
     SELECT 
         c.case_id,
         CASE 
              /* if ALL motorcyclists in the crash wore helmets → “used”, 
                 otherwise → “not_used”                                   */
              WHEN MIN(mp.helmet_used)=1 THEN 'used'
              ELSE 'not_used'
         END AS helmet_group
     FROM collisions  c
     JOIN motorcyclist_parties mp
           ON mp.case_id = c.case_id
     WHERE c.motorcycle_collision = 1                     -- motorcycle collisions only
     GROUP BY c.case_id
),
group_stats AS (                         -- collisions & fatalities per helmet group
     SELECT
         chg.helmet_group,
         COUNT(DISTINCT chg.case_id)                  AS collisions,
         SUM(COALESCE(c.motorcyclist_killed_count,0)) AS fatalities
     FROM collision_helmet_group chg
     JOIN collisions c
           ON c.case_id = chg.case_id
     GROUP BY chg.helmet_group
)
SELECT
    ROUND( MAX( CASE WHEN helmet_group='used'     THEN fatalities*100.0/collisions END ), 4)
      AS helmet_used_fatality_rate_pct,
    ROUND( MAX( CASE WHEN helmet_group='not_used' THEN fatalities*100.0/collisions END ), 4)
      AS helmet_not_used_fatality_rate_pct
FROM group_stats;