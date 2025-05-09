WITH
    -- 1. Shah Rukh Khan’s person‑id
    srk AS (
        SELECT PID
        FROM Person
        WHERE lower(trim(Name)) = 'shah rukh khan'
    ),

    -- 2. All movies Shah Rukh Khan acted in
    srk_movies AS (
        SELECT DISTINCT MID
        FROM M_Cast
        WHERE PID = (SELECT PID FROM srk)
    ),

    -- 3. “Distance‑1” actors: every actor who appeared with Shah Rukh Khan
    level1_actors AS (
        SELECT DISTINCT PID
        FROM M_Cast
        WHERE MID IN (SELECT MID FROM srk_movies)
          AND PID <> (SELECT PID FROM srk)
    ),

    -- 4. Movies that contain at least one distance‑1 actor
    level1_movies AS (
        SELECT DISTINCT MID
        FROM M_Cast
        WHERE PID IN (SELECT PID FROM level1_actors)
    ),

    -- 5. “Distance‑2” candidates: actors in those movies,
    --    excluding Shah Rukh Khan and every distance‑1 actor
    level2_candidates AS (
        SELECT DISTINCT PID
        FROM M_Cast
        WHERE MID IN (SELECT MID FROM level1_movies)
          AND PID NOT IN (SELECT PID FROM level1_actors)
          AND PID <> (SELECT PID FROM srk)
    )

-- 6. Final answer: number of actors whose Shah Rukh number is exactly 2
SELECT COUNT(DISTINCT PID) AS num_actors_with_shahrukh_number_2
FROM level2_candidates;