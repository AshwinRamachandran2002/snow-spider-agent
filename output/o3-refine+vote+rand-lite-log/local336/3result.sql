WITH
-- keep just the grid (lap 0) and first five race‑laps
pos AS (
    SELECT
        race_id,
        driver_id,
        lap,
        position
    FROM lap_positions
    WHERE lap BETWEEN 0 AND 5
),

/*  position change for every driver from the previous lap
    (positive “gained” = number of places the driver moved forward) */
pos_change AS (
    SELECT
        c.race_id,
        c.driver_id,
        c.lap,               -- current lap 1‑5
        p.position  AS prev_pos,
        c.position  AS cur_pos,
        p.position - c.position AS gained     -- > 0  ⇒  an over‑take
    FROM pos  c
    JOIN pos  p
      ON  p.race_id  = c.race_id
      AND p.driver_id= c.driver_id
      AND p.lap      = c.lap - 1
    WHERE c.lap BETWEEN 1 AND 5
),

/* every individual over‑take (driver gained ≥ 1 place) */
overtakes AS (
    SELECT * FROM pos_change
    WHERE gained > 0
),

/* ───────────── category: start (grid → lap 1) ───────────── */
start_passes AS (
    SELECT COALESCE(SUM(gained),0) AS cnt
    FROM   overtakes
    WHERE  lap = 1                       -- only grid‑start changes
),

/* ───────────── category: pit‑stop induced ───────────── */
pit_losses AS (        -- how many places each pitting driver loses
    SELECT
        ps.race_id,
        ps.driver_id,
        ps.lap,
        (c.position - p.position) AS lost
    FROM pit_stops      ps
    JOIN pos            p  ON p.race_id = ps.race_id
                          AND p.driver_id = ps.driver_id
                          AND p.lap = ps.lap - 1
    JOIN pos            c  ON c.race_id = ps.race_id
                          AND c.driver_id = ps.driver_id
                          AND c.lap = ps.lap
    WHERE ps.lap BETWEEN 1 AND 5
),
pit_passes AS (
    SELECT COALESCE(SUM(lost),0) AS cnt
    FROM   pit_losses
    WHERE  lost > 0
),

/* ───────────── category: retirement induced ───────────── */
ret_losses AS (
    SELECT
        r.race_id,
        r.driver_id,
        r.lap,
        (COALESCE(c.position, 1000) - p.position) AS lost   -- driver drops to back / out
    FROM retirements     r
    LEFT JOIN pos        p  ON p.race_id = r.race_id
                           AND p.driver_id = r.driver_id
                           AND p.lap = r.lap - 1
    LEFT JOIN pos        c  ON c.race_id = r.race_id
                           AND c.driver_id = r.driver_id
                           AND c.lap = r.lap          -- usually missing after retirement
    WHERE r.lap BETWEEN 1 AND 5
),
ret_passes AS (
    SELECT COALESCE(SUM(lost),0) AS cnt
    FROM   ret_losses
    WHERE  lost > 0
),

/* ───────────── total overtakes (all causes) ───────────── */
total_passes AS (
    SELECT COALESCE(SUM(gained),0) AS cnt
    FROM   overtakes
),

/* ───────────── remaining = standard on‑track passes ───────────── */
standard_passes AS (
    SELECT
        total_passes.cnt
      - start_passes.cnt
      - pit_passes.cnt
      - ret_passes.cnt          AS cnt
    FROM total_passes, start_passes, pit_passes, ret_passes
)

/* ───────────── final result ───────────── */
SELECT
    ret_passes.cnt     AS retirement_overtakes,
    pit_passes.cnt     AS pit_stop_overtakes,
    start_passes.cnt   AS start_related_overtakes,
    standard_passes.cnt AS standard_on_track_overtakes
FROM
    ret_passes, pit_passes, start_passes, standard_passes;