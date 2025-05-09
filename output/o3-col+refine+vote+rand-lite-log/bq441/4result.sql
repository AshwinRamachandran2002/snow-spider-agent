/*  Critical crash-, person- and vehicle-level details for the
    2015 Fatality Analysis Reporting System (FARS).

    Each row represents one person involved in a 2015 fatal crash and
    includes the derived fields described in the info document.         */

SELECT
  /* ------------------- Crash-level fields --------------------------- */
  a.consecutive_number                           AS consecutive_number,
  a.county                                       AS county,
  a.type_of_intersection                         AS type_of_intersection,
  a.light_condition                              AS light_condition,
  a.atmospheric_conditions_1                     AS atmospheric_conditions_1,
  a.hour_of_crash                                AS hour_of_crash,
  a.functional_system                            AS functional_system,
  a.related_factors_crash_level_1                AS related_factors,

  /* Time-delay metrics */
  CASE
    WHEN a.hour_of_ems_arrival_at_hospital BETWEEN 0 AND 23
    THEN a.hour_of_ems_arrival_at_hospital - a.hour_of_crash
  END                                            AS delay_to_hospital,
  CASE
    WHEN a.hour_of_arrival_at_scene BETWEEN 0 AND 23
    THEN a.hour_of_arrival_at_scene - a.hour_of_crash
  END                                            AS delay_to_scene,

  /* ------------------- Person-level fields -------------------------- */
  p.age                                          AS age,
  p.person_type                                  AS person_type,
  p.seating_position                             AS seating_position,

  /* Restraint score (0-1) */
  CASE
    WHEN p.restraint_system_helmet_use = 0 THEN 0
    WHEN p.restraint_system_helmet_use = 1 THEN 0.33
    WHEN p.restraint_system_helmet_use = 2 THEN 0.67
    WHEN p.restraint_system_helmet_use = 3 THEN 1.00
    ELSE 0.50
  END                                            AS restraint,

  /* Survival flag (1 = survived, 0 = fatal) */
  CASE WHEN p.injury_severity = 4 THEN 1 ELSE 0 END AS survived,

  /* Alcohol / drug involvement (binary) */
  CASE WHEN LOWER(p.police_reported_alcohol_involvement) LIKE '%yes%' THEN 1 ELSE 0 END
                                                AS alcohol,
  CASE WHEN LOWER(p.police_reported_drug_involvement)   LIKE '%yes%' THEN 1 ELSE 0 END
                                                AS drugs,

  p.related_factors_person_level1               AS related_factors_person_level1,

  /* Binary air-bag deployment indicator (person-level) */
  CASE
    WHEN p.air_bag_deployed BETWEEN 1 AND 9 THEN 1
    ELSE 0
  END                                            AS airbag,

  /* ------------------- Vehicle-level fields ------------------------- */
  v.travel_speed                                 AS travel_speed,

  /* Speeding flag (binary) */
  CASE WHEN LOWER(v.speeding_related) LIKE '%yes%' THEN 1 ELSE 0 END
                                                AS speeding_related,

  v.extent_of_damage                            AS extent_of_damage,
  v.body_type                                   AS body_type,
  v.vehicle_removal                             AS vehicle_removal,

  /* Binary rollover indicator */
  CASE WHEN v.rollover = 'No Rollover' THEN 0 ELSE 1 END
                                                AS rollover,

  /* Manner of collision – capped at 11 */
  CASE
    WHEN v.manner_of_collision > 11 THEN 11
    ELSE v.manner_of_collision
  END                                            AS manner_of_collision,

  /* Roadway surface condition – capped at 8 */
  CASE
    WHEN v.roadway_surface_condition > 8 THEN 8
    ELSE v.roadway_surface_condition
  END                                            AS roadway_surface_condition,

  /* First / most harmful events – set to 0 when ≥ 90 */
  CASE
    WHEN v.first_harmful_event < 90 THEN v.first_harmful_event ELSE 0
  END                                            AS first_harmful_event,
  CASE
    WHEN v.most_harmful_event < 90 THEN v.most_harmful_event ELSE 0
  END                                            AS most_harmful_event
FROM
  `bigquery-public-data.nhtsa_traffic_fatalities.accident_2015` AS a
JOIN
  `bigquery-public-data.nhtsa_traffic_fatalities.person_2015`   AS p
    ON a.consecutive_number = p.consecutive_number
JOIN
  `bigquery-public-data.nhtsa_traffic_fatalities.vehicle_2015`  AS v
    ON a.consecutive_number = v.consecutive_number;