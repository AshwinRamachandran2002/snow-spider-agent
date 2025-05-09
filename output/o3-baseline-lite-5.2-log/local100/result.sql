WITH
-- 1. Shah Rukh Khan’s person‑id(s)
srk AS (
    SELECT PID
    FROM Person
    WHERE lower(trim(Name)) LIKE '%shah%'      -- “Shah/ Shahrukh …”
      AND lower(trim(Name)) LIKE '%rukh%'
      AND lower(trim(Name)) LIKE '%khan%'      -- “… Khan”
),
-- 2. Movies in which Shah Rukh Khan appeared
srk_movies AS (
    SELECT DISTINCT MID
    FROM M_Cast
    WHERE PID IN (SELECT PID FROM srk)
),
-- 3. All actors who appeared in a Shah Rukh Khan movie    Shahrukh‑number 1
srk1_actors AS (
    SELECT DISTINCT PID
    FROM M_Cast
    WHERE MID IN (SELECT MID FROM srk_movies)
      AND PID NOT IN (SELECT PID FROM srk)     -- exclude Shah Rukh Khan himself
),
-- 4. Co‑actors of those number‑1 actors (i.e. acted with someone who acted with SRK)
co_actors AS (
    SELECT DISTINCT mc2.PID
    FROM M_Cast AS mc1
    JOIN M_Cast AS mc2
         ON mc1.MID = mc2.MID                  -- same movie
    WHERE mc1.PID IN (SELECT PID FROM srk1_actors)
      AND mc2.PID NOT IN (SELECT PID FROM srk1_actors)  -- not already number‑1
      AND mc2.PID NOT IN (SELECT PID FROM srk)          -- not Shah Rukh Khan
)
-- 5. The required actors: Shahrukh‑number 2
SELECT COUNT(DISTINCT PID) AS actors_with_shahrukh_number_2
FROM co_actors;