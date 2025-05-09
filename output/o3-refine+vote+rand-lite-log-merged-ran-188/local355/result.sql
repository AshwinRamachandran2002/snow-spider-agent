WITH paired AS (
    /* locate every gap (hiatus) between two consecutive drives
       of the same driver in the same year                       */
    SELECT
        d1.year,
        d1.driver_id,
        d1.constructor_id        AS constructor_before,
        d1.last_round            AS last_round_before,
        d2.constructor_id        AS constructor_after,
        d2.first_round           AS first_round_after,
        (d2.first_round - d1.last_round - 1)      AS missed_races,
        (d1.last_round + 1)                       AS first_missed_round,
        (d2.first_round - 1)                      AS last_missed_round
    FROM drives AS d1
    JOIN drives AS d2
         ON d2.year       = d1.year
        AND d2.driver_id  = d1.driver_id
        AND d2.first_round > d1.last_round
        /* ensure d2 is the immediately following stint */
        AND d2.first_round = (
              SELECT MIN(d3.first_round)
              FROM drives AS d3
              WHERE d3.year       = d1.year
                AND d3.driver_id  = d1.driver_id
                AND d3.first_round > d1.last_round
          )
    /* conditions from the task */
    WHERE (d2.first_round - d1.last_round - 1) BETWEEN 1 AND 2   -- missed < 3 races
      AND d1.constructor_id <> d2.constructor_id                 -- switched teams
)

SELECT
    AVG(first_missed_round) AS average_first_missed_round,
    AVG(last_missed_round)  AS average_last_missed_round
FROM paired;