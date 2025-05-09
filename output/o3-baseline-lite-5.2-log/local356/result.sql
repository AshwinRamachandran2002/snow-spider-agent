WITH race_lap_positions AS (
    /* keep only real race laps */
    SELECT
        race_id,
        driver_id,
        lap,
        position
    FROM lap_positions
    WHERE lap_type = 'Race'
),
/* laps that must be ignored: first‑lap changes, any lap in which
   at least one pit‑stop happened, or any lap in which a retirement
   occurred                                                */
ignored_laps AS (
    /* first lap of every race                                 */
    SELECT DISTINCT race_id, 1 AS lap
    FROM race_lap_positions

    UNION

    /* laps with at least one pit‑stop                          */
    SELECT DISTINCT race_id, lap
    FROM pit_stops

    UNION

    /* laps with at least one retirement                        */
    SELECT DISTINCT race_id, lap
    FROM retirements
),
/* position deltas between two consecutive laps that are NOT in the
   ignored‑laps list                                           */
valid_position_changes AS (
    SELECT
        cur.race_id,
        cur.driver_id,
        cur.lap,                       /* current lap  (t)          */
        prev.position  AS prev_pos,    /* position at lap t‑1       */
        cur.position   AS curr_pos,    /* position at lap t         */
        (prev.position - cur.position) AS delta   /*  +ve = gained  */
    FROM race_lap_positions  cur
    JOIN race_lap_positions  prev
         ON  cur.race_id  = prev.race_id
         AND cur.driver_id = prev.driver_id
         AND cur.lap      = prev.lap + 1          /* consecutive   */
    LEFT JOIN ignored_laps  ig                  /* discard laps to ignore */
         ON  cur.race_id = ig.race_id
         AND cur.lap     = ig.lap
    WHERE ig.lap IS NULL
),
/* aggregate gains (overtakes made) and losses (being overtaken) */
driver_overtake_balance AS (
    SELECT
        driver_id,
        SUM( CASE WHEN delta > 0 THEN  delta ELSE 0 END)           AS overtakes_made,
        SUM( CASE WHEN delta < 0 THEN -delta ELSE 0 END)           AS overtakes_suffered
    FROM valid_position_changes
    GROUP BY driver_id
)
/* final answer: drivers whose losses exceed their gains          */
SELECT
    d.full_name
FROM driver_overtake_balance  dob
JOIN drivers_ext              d
     ON d.driver_id = dob.driver_id
WHERE dob.overtakes_suffered > dob.overtakes_made
ORDER BY d.full_name;