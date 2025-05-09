-- Compile the “critical details on traffic accidents in 2015”
-- (one row per PERSON, enriched with crash– and vehicle-level data).

WITH crash AS (
  SELECT
    consecutive_number,
    county,
    type_of_intersection,
    light_condition,
    atmospheric_conditions_1,
    hour_of_crash,
    functional_system,
    related_factors_crash_level_1                         AS related_factors,
    /* delay until EMS reached hospital */
    CASE
      WHEN hour_of_ems_arrival_at_hospital BETWEEN 0 AND 23
      THEN hour_of_ems_arrival_at_hospital - hour_of_crash
    END                                                   AS delay_to_hospital,
    /* delay until EMS reached scene */
    CASE
      WHEN hour_of_arrival_at_scene BETWEEN 0 AND 23
      THEN hour_of_arrival_at_scene - hour_of_crash
    END                                                   AS delay_to_scene
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2015`
),

/* pick ONE representative vehicle (the first by VEHICLE_NUMBER) per crash */
vehicle_first AS (
  SELECT
    v.*,
    ROW_NUMBER() OVER (PARTITION BY consecutive_number ORDER BY vehicle_number) AS rn
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.vehicle_2015` v
),
vehicle AS (
  SELECT
    consecutive_number,
    travel_speed,
    /* binary flag for any “Yes …” wording */
    CASE WHEN LOWER(speeding_related) LIKE 'yes%'                 THEN 1 ELSE 0 END AS speeding_related,
    extent_of_damage,
    body_type,
    vehicle_removal,
    /* cap at 11 */
    CASE WHEN manner_of_collision            > 11                 THEN 11 ELSE manner_of_collision END AS manner_of_collision,
    /* cap at 8 */
    CASE WHEN roadway_surface_condition      > 8                  THEN 8  ELSE roadway_surface_condition END AS roadway_surface_condition,
    /* keep code only if < 90, otherwise 0 */
    CASE WHEN first_harmful_event            < 90                 THEN first_harmful_event  ELSE 0 END AS first_harmful_event,
    CASE WHEN most_harmful_event             < 90                 THEN most_harmful_event   ELSE 0 END AS most_harmful_event,
    /* binary rollover flag */
    CASE WHEN LOWER(rollover) LIKE '%no rollover%'                THEN 0 ELSE 1 END AS rollover
  FROM vehicle_first
  WHERE rn = 1
),

person AS (
  SELECT
    consecutive_number,
    age,
    person_type,
    seating_position,
    /* map restraint scale */
    CASE restraint_system_helmet_use
         WHEN 0 THEN 0.0
         WHEN 1 THEN 0.33
         WHEN 2 THEN 0.67
         WHEN 3 THEN 1.00
         ELSE 0.5
    END                                                   AS restraint,
    /* injury severity 4  → survived */
    CASE WHEN injury_severity = 4                         THEN 1 ELSE 0 END  AS survived,
    /* 1–9  → deployed */
    CASE WHEN air_bag_deployed BETWEEN 1 AND 9            THEN 1 ELSE 0 END  AS airbag,
    /* text contains “Yes …” */
    CASE WHEN LOWER(police_reported_alcohol_involvement) LIKE 'yes%' THEN 1 ELSE 0 END AS alcohol,
    CASE WHEN LOWER(police_reported_drug_involvement)   LIKE 'yes%' THEN 1 ELSE 0 END AS drugs,
    related_factors_person_level1
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.person_2015`
)

SELECT
  /* crash-level */
  p.consecutive_number,
  c.county,
  c.type_of_intersection,
  c.light_condition,
  c.atmospheric_conditions_1,
  c.hour_of_crash,
  c.functional_system,
  c.related_factors,
  c.delay_to_hospital,
  c.delay_to_scene,

  /* person-level */
  p.age,
  p.person_type,
  p.seating_position,
  p.restraint,
  p.survived,
  p.airbag,
  p.alcohol,
  p.drugs,
  p.related_factors_person_level1,

  /* vehicle-level */
  v.rollover,
  v.travel_speed,
  v.speeding_related,
  v.extent_of_damage,
  v.body_type,
  v.vehicle_removal,
  v.manner_of_collision,
  v.roadway_surface_condition,
  v.first_harmful_event,
  v.most_harmful_event
FROM person  p
LEFT JOIN crash   c USING (consecutive_number)
LEFT JOIN vehicle v USING (consecutive_number);