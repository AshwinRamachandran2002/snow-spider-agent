WITH driver_counts AS (
  SELECT
    results.driver_id,
    races.year,
    COUNT(DISTINCT races.round) AS num_rounds
  FROM
    results
    JOIN races ON results.race_id = races.race_id
  WHERE
    races.year BETWEEN 1950 AND 1959
  GROUP BY
    results.driver_id,
    races.year
  HAVING
    num_rounds >= 2
),
first_race_dates AS (
  SELECT
    results.driver_id,
    races.year,
    MIN(races.date) AS first_race_date
  FROM
    results
    JOIN races ON results.race_id = races.race_id
  WHERE
    (results.driver_id, races.year) IN (SELECT driver_id, year FROM driver_counts)
  GROUP BY
    results.driver_id,
    races.year
),
last_race_dates AS (
  SELECT
    results.driver_id,
    races.year,
    MAX(races.date) AS last_race_date
  FROM
    results
    JOIN races ON results.race_id = races.race_id
  WHERE
    (results.driver_id, races.year) IN (SELECT driver_id, year FROM driver_counts)
  GROUP BY
    results.driver_id,
    races.year
),
first_race_constructors AS (
  SELECT
    DISTINCT frd.driver_id,
    frd.year,
    results.constructor_id AS constructor_id
  FROM
    first_race_dates frd
    JOIN results ON results.driver_id = frd.driver_id
    JOIN races ON results.race_id = races.race_id
  WHERE
    races.year = frd.year AND races.date = frd.first_race_date
),
last_race_constructors AS (
  SELECT
    DISTINCT lrd.driver_id,
    lrd.year,
    results.constructor_id AS constructor_id
  FROM
    last_race_dates lrd
    JOIN results ON results.driver_id = lrd.driver_id
    JOIN races ON results.race_id = races.race_id
  WHERE
    races.year = lrd.year AND races.date = lrd.last_race_date
)
SELECT DISTINCT
  frc.driver_id,
  drivers.full_name AS driver_name,
  frc.year,
  frc.constructor_id,
  constructors.name AS constructor_name
FROM
  first_race_constructors frc
  JOIN last_race_constructors lrc ON frc.driver_id = lrc.driver_id AND frc.year = lrc.year AND frc.constructor_id = lrc.constructor_id
  JOIN driver_counts dc ON frc.driver_id = dc.driver_id AND frc.year = dc.year
  JOIN drivers ON frc.driver_id = drivers.driver_id
  JOIN constructors ON frc.constructor_id = constructors.constructor_id
ORDER BY
  frc.driver_id,
  frc.year;