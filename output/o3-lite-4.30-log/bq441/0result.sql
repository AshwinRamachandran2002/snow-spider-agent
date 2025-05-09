SELECT
  /* crash date ------------------------------------------------------------- */
  COALESCE(DATE(timestamp_of_crash),
           DATE(year_of_crash, month_of_crash, day_of_crash))          AS accident_date,

  /* latitude,longitude to 4 decimal places -------------------------------- */
  CASE
    WHEN latitude  BETWEEN -90  AND  90
     AND longitude BETWEEN -180 AND 180
    THEN FORMAT('%.4f,%.4f', latitude, longitude)
  END                                                                   AS travel_coordinates,

  /* casualty counts -------------------------------------------------------- */
  number_of_fatalities                                                  AS fatalities,

  GREATEST(
      COALESCE(number_of_persons_in_motor_vehicles_in_transport_mvit, 0) +
      COALESCE(number_of_persons_not_in_motor_vehicles_in_transport_mvit, 0) -
      COALESCE(number_of_fatalities, 0),
      0)                                                                AS injuries,

  COALESCE(number_of_persons_in_motor_vehicles_in_transport_mvit, 0) +
  COALESCE(number_of_persons_not_in_motor_vehicles_in_transport_mvit, 0) AS total_casualties,

  /* road name + state ------------------------------------------------------ */
  CONCAT(
      COALESCE(TRIM(trafficway_identifier), 'Unknown Road'),
      ', ',
      COALESCE(state_name, 'Unknown State')
  )                                                                      AS location_description
FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2015`;