WITH
    shahrukh AS (
        SELECT PID
        FROM Person
        WHERE lower(trim(Name)) LIKE '%shahrukh%' AND lower(trim(Name)) LIKE '%khan%'
    ),
    srk_movies AS (
        SELECT DISTINCT MID
        FROM M_Cast
        WHERE PID IN (SELECT PID FROM shahrukh)
    ),
    level1_actors AS (      -- Shahrukh number = 1
        SELECT DISTINCT PID
        FROM M_Cast
        WHERE MID IN (SELECT MID FROM srk_movies)
          AND PID NOT IN (SELECT PID FROM shahrukh)
    ),
    movies_with_level1 AS (
        SELECT DISTINCT MID
        FROM M_Cast
        WHERE PID IN (SELECT PID FROM level1_actors)
    ),
    potential_level2 AS (
        SELECT DISTINCT PID
        FROM M_Cast
        WHERE MID IN (SELECT MID FROM movies_with_level1)
          AND PID NOT IN (SELECT PID FROM shahrukh)
    ),
    shahrukh_number2 AS (
        SELECT PID
        FROM potential_level2
        WHERE PID NOT IN (SELECT PID FROM level1_actors)   -- exclude those with number 1
    )
SELECT COUNT(*) AS actors_with_shahrukh_number_2
FROM shahrukh_number2;