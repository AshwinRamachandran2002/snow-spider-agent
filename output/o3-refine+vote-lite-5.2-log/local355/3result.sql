WITH driver_years AS (
    /* every (driver , year) in which the driver took part in ≥1 race */
    SELECT DISTINCT res.driver_id ,
           r.year
    FROM results res
    JOIN races   r ON r.race_id = res.race_id
),
driver_year_rounds AS (
    /* for each of those (driver , year) keep every round of that season
       together with a “participated / constructor_id” flag                */
    SELECT dy.driver_id ,
           r.year                                AS season_year ,
           r.round                               AS rnd ,
           MAX(res.constructor_id)               AS constructor_id ,   -- NULL if absent
           CASE WHEN res.result_id IS NULL THEN 0 ELSE 1 END AS took_part
    FROM driver_years dy
    JOIN races              r   ON r.year = dy.year
    LEFT JOIN results       res ON res.race_id = r.race_id
                               AND res.driver_id = dy.driver_id
    GROUP BY dy.driver_id , r.year , r.round
),
add_prev_next AS (
    /* for every row store last/next round in which the driver did race     */
    SELECT dyr.* ,
           ( SELECT MAX(r2.rnd)
             FROM driver_year_rounds r2
             WHERE r2.driver_id = dyr.driver_id
               AND r2.season_year = dyr.season_year
               AND r2.took_part   = 1
               AND r2.rnd        < dyr.rnd ) AS prev_part_round ,
           ( SELECT MIN(r2.rnd)
             FROM driver_year_rounds r2
             WHERE r2.driver_id = dyr.driver_id
               AND r2.season_year = dyr.season_year
               AND r2.took_part   = 1
               AND r2.rnd        > dyr.rnd ) AS next_part_round
    FROM driver_year_rounds dyr
),
missing_rows AS (
    /* only the rounds that were missed AND surrounded by participations    */
    SELECT driver_id ,
           season_year ,
           rnd ,
           prev_part_round ,
           next_part_round ,
           rnd - ROW_NUMBER() OVER (PARTITION BY driver_id , season_year
                                     ORDER BY rnd)      AS grp_id
    FROM add_prev_next
    WHERE took_part = 0
      AND prev_part_round IS NOT NULL
      AND next_part_round IS NOT NULL
),
gaps AS (
    /* each contiguous “hiatus” (set of missed rounds)                      */
    SELECT driver_id ,
           season_year ,
           MIN(rnd)                 AS first_missed_round ,
           MAX(rnd)                 AS last_missed_round ,
           COUNT(*)                 AS missed_cnt ,
           MAX(prev_part_round)     AS prev_round ,
           MAX(next_part_round)     AS next_round
    FROM missing_rows
    GROUP BY driver_id , season_year , grp_id
    HAVING missed_cnt < 3          -- < 3 races missed
),
gaps_switched AS (
    /* keep only the gaps where constructor before ≠ constructor after      */
    SELECT g.first_missed_round ,
           g.last_missed_round
    FROM gaps g
    JOIN driver_year_rounds pr
         ON pr.driver_id   = g.driver_id
        AND pr.season_year = g.season_year
        AND pr.rnd         = g.prev_round
    JOIN driver_year_rounds nr
         ON nr.driver_id   = g.driver_id
        AND nr.season_year = g.season_year
        AND nr.rnd         = g.next_round
    WHERE pr.constructor_id IS NOT NULL
      AND nr.constructor_id IS NOT NULL
      AND pr.constructor_id <> nr.constructor_id
)
SELECT ROUND(AVG(first_missed_round),4) AS avg_first_missed_round ,
       ROUND(AVG(last_missed_round),4)  AS avg_last_missed_round
FROM   gaps_switched;