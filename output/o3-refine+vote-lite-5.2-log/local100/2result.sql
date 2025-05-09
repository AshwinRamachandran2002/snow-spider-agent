WITH
shahrukh AS (
    /* Shahrukh Khan’s PID(s)                                              */
    SELECT PID
    FROM Person
    WHERE lower(trim(Name)) LIKE '%shahrukh%' 
       OR lower(trim(Name)) LIKE '%shah rukh%'
),
srk_movies AS (
    /* Movies that feature Shahrukh Khan                                   */
    SELECT DISTINCT MID
    FROM M_Cast
    WHERE trim(PID) IN (SELECT PID FROM shahrukh)
),
level1_actors AS (
    /* Actors who have appeared with Shahrukh Khan (Shahrukh‑number = 1)   */
    SELECT DISTINCT trim(PID) AS PID
    FROM M_Cast
    WHERE MID IN (SELECT MID FROM srk_movies)
      AND trim(PID) NOT IN (SELECT PID FROM shahrukh)
),
possible_level2 AS (
    /* Actors who have appeared with a level‑1 actor                       */
    SELECT DISTINCT trim(c2.PID) AS PID
    FROM M_Cast  c1
    JOIN M_Cast  c2
      ON c1.MID = c2.MID
    WHERE trim(c1.PID) IN (SELECT PID FROM level1_actors)
      AND trim(c2.PID) NOT IN (SELECT PID FROM level1_actors)
      AND trim(c2.PID) NOT IN (SELECT PID FROM shahrukh)
),
level2_actors AS (
    /* Keep only those who have NEVER appeared with Shahrukh Khan directly */
    SELECT PID
    FROM possible_level2
    WHERE PID NOT IN (
        SELECT DISTINCT trim(PID)
        FROM M_Cast
        WHERE MID IN (SELECT MID FROM srk_movies)
    )
)
SELECT COUNT(*) AS num_level2_actors
FROM   level2_actors;