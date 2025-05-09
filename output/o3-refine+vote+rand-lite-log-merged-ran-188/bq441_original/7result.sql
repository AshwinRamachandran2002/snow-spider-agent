/*  Critical details of 2015 traffic‑fatality crashes                    */
/*  – accident level, enriched with driver‑ and vehicle‑level fields    */
/*  – one record per crash (driver = person_type 1, vehicle_number = 1) */

WITH accident AS (
  SELECT
    consecutive_number,
    county,
    type_of_intersection,
    light_condition,
    atmospheric_conditions_1,
    hour_of_crash,
    functional_system,
    related_factors_crash_level_1          AS related_factors,
    /* delays (valid only when arrival hour is 0‑23) */
    CASE
      WHEN hour_of_ems_arrival_at_hospital BETWEEN 0 AND 23
      THEN hour_of_ems_arrival_at_hospital - hour_of_crash
    END                                    AS delay_to_hospital,
    CASE
      WHEN hour_of_arrival_at_scene BETWEEN 0 AND 23
      THEN hour_of_arrival_at_scene - hour_of_crash
    END                                    AS delay_to_scene
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2015`
),

driver AS (
  SELECT
    consecutive_number,
    age,
    person_type,
    seating_position,
    restraint_system_helmet_use,
    injury_severity,
    /* binary flags */
    IF(rollover LIKE '%Rollover%', 1, 0)                                        AS rollover,
    IF(air_bag_deployed BETWEEN 1 AND 9, 1, 0)                                  AS airbag,
    IF(LOWER(police_reported_alcohol_involvement) LIKE '%yes%', 1, 0)           AS alcohol,
    IF(LOWER(police_reported_drug_involvement)   LIKE '%yes%', 1, 0)            AS drugs,
    related_factors_person_level1
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.person_2015`
  WHERE person_type = 1            -- keep the driver to get one row / crash
),

vehicle AS (
  SELECT
    consecutive_number,
    travel_speed,
    IF(LOWER(speeding_related) LIKE '%yes%', 1, 0)                              AS speeding_related,
    extent_of_damage,
    body_type,
    vehicle_removal,
    /* capped / re‑coded fields */
    IF(manner_of_collision > 11, 11, manner_of_collision)                      AS manner_of_collision,
    IF(roadway_surface_condition > 8, 8, roadway_surface_condition)            AS roadway_surface_condition,
    IF(first_harmful_event  < 90, first_harmful_event, 0)                      AS first_harmful_event,
    IF(most_harmful_event   < 90, most_harmful_event, 0)                       AS most_harmful_event
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.vehicle_2015`
  WHERE vehicle_number = 1
)

SELECT
  a.consecutive_number,
  a.county,
  a.type_of_intersection,
  a.light_condition,
  a.atmospheric_conditions_1,
  a.hour_of_crash,
  a.functional_system,
  a.related_factors,
  a.delay_to_hospital,
  a.delay_to_scene,

  d.age,
  d.person_type,
  d.seating_position,
  /* restraint scale */
  CASE d.restraint_system_helmet_use
      WHEN 0 THEN 0
      WHEN 1 THEN 0.33
      WHEN 2 THEN 0.67
      WHEN 3 THEN 1.0
      ELSE 0.5
  END                           AS restraint,

  IF(d.injury_severity = 4, 1, 0)  AS survived,
  d.rollover,
  d.airbag,
  d.alcohol,
  d.drugs,
  d.related_factors_person_level1,

  v.travel_speed,
  v.speeding_related,
  v.extent_of_damage,
  v.body_type,
  v.vehicle_removal,
  v.manner_of_collision,
  v.roadway_surface_condition,
  v.first_harmful_event,
  v.most_harmful_event
FROM accident a
LEFT JOIN driver  d USING (consecutive_number)
LEFT JOIN vehicle v USING (consecutive_number);