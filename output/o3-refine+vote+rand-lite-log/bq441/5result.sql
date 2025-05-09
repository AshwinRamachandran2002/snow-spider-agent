/*  Critical details for every person/vehicle involved in a 2015 fatal crash
    (one row per person) – field names follow the supplied info list          */

WITH accidents AS (
  SELECT
      state_number,
      consecutive_number,
      county,
      type_of_intersection,
      light_condition,
      atmospheric_conditions_1,
      hour_of_crash,
      functional_system,
      related_factors_crash_level_1                  AS related_factors,
      /* delays */
      CASE
        WHEN hour_of_ems_arrival_at_hospital BETWEEN 0 AND 23
        THEN hour_of_ems_arrival_at_hospital - hour_of_crash
      END                                            AS delay_to_hospital,
      CASE
        WHEN hour_of_arrival_at_scene BETWEEN 0 AND 23
        THEN hour_of_arrival_at_scene - hour_of_crash
      END                                            AS delay_to_scene,
      manner_of_collision,
      first_harmful_event
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2015`
),

vehicles AS (
  SELECT
      state_number,
      consecutive_number,
      vehicle_number,
      travel_speed,
      speeding_related,
      extent_of_damage,
      body_type,
      vehicle_removal,
      rollover,
      most_harmful_event,
      roadway_surface_condition
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.vehicle_2015`
),

persons AS (
  SELECT
      state_number,
      consecutive_number,
      vehicle_number,
      person_number,
      age,
      person_type,
      seating_position,
      restraint_system_helmet_use,
      injury_severity,
      air_bag_deployed,
      police_reported_alcohol_involvement,
      police_reported_drug_involvement,
      related_factors_person_level1
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.person_2015`
)

SELECT
    acc.consecutive_number,
    acc.county,
    acc.type_of_intersection,
    acc.light_condition,
    acc.atmospheric_conditions_1,
    acc.hour_of_crash,
    acc.functional_system,
    acc.related_factors,
    acc.delay_to_hospital,
    acc.delay_to_scene,
    per.age,
    per.person_type,
    per.seating_position,

    /* restraint scale 0‑1 */
    CASE per.restraint_system_helmet_use
         WHEN 0 THEN 0
         WHEN 1 THEN 0.33
         WHEN 2 THEN 0.67
         WHEN 3 THEN 1.0
         ELSE 0.5
    END                                             AS restraint,

    /* survived flag */
    CASE WHEN per.injury_severity = 4 THEN 1 ELSE 0 END        AS survived,

    /* rollover flag (0 = none, 1 = any) */
    CASE WHEN LOWER(veh.rollover) LIKE '%no rollover%' THEN 0 ELSE 1 END
                                                               AS rollover,

    /* air‑bag deployed flag */
    CASE WHEN per.air_bag_deployed BETWEEN 1 AND 9 THEN 1 ELSE 0 END
                                                               AS airbag,

    /* alcohol & drug flags */
    CASE WHEN LOWER(per.police_reported_alcohol_involvement) LIKE '%yes%' THEN 1 ELSE 0 END
                                                               AS alcohol,
    CASE WHEN LOWER(per.police_reported_drug_involvement)    LIKE '%yes%' THEN 1 ELSE 0 END
                                                               AS drugs,

    per.related_factors_person_level1,
    veh.travel_speed,

    /* speeding‑related flag */
    CASE WHEN LOWER(veh.speeding_related) LIKE '%yes%' THEN 1 ELSE 0 END
                                                               AS speeding_related,

    veh.extent_of_damage,
    veh.body_type,
    veh.vehicle_removal,

    /* capped / recoded crash variables */
    LEAST(acc.manner_of_collision, 11)                          AS manner_of_collision,
    CASE
        WHEN veh.roadway_surface_condition > 11 THEN 8
        ELSE veh.roadway_surface_condition
    END                                                         AS roadway_surface_condition,
    CASE
        WHEN acc.first_harmful_event < 90 THEN acc.first_harmful_event
        ELSE 0
    END                                                         AS first_harmful_event,
    CASE
        WHEN veh.most_harmful_event < 90 THEN veh.most_harmful_event
        ELSE 0
    END                                                         AS most_harmful_event
FROM accidents acc
JOIN vehicles  veh USING (state_number, consecutive_number)
JOIN persons   per USING (state_number, consecutive_number, vehicle_number);