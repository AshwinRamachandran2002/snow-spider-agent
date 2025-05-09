WITH shahrukh AS (
    SELECT PID
    FROM Person
    WHERE TRIM(Name) LIKE '%Shahrukh Khan%'          -- Shahrukh Khan's PID
),
shahrukh_movies AS (                                -- Movies with Shahrukh Khan
    SELECT DISTINCT MID
    FROM M_Cast
    WHERE PID IN (SELECT PID FROM shahrukh)
),
direct_costars AS (                                 -- Actors who acted *with* Shahrukh
    SELECT DISTINCT PID
    FROM M_Cast
    WHERE MID IN (SELECT MID FROM shahrukh_movies)
      AND PID NOT IN (SELECT PID FROM shahrukh)
),
movies_with_direct_costars AS (                     -- Movies that contain a direct co‑star
    SELECT DISTINCT MID
    FROM M_Cast
    WHERE PID IN (SELECT PID FROM direct_costars)
),
indirect_costars AS (                               -- Everyone who acted in those movies
    SELECT DISTINCT PID
    FROM M_Cast
    WHERE MID IN (SELECT MID FROM movies_with_direct_costars)
),
shahrukh_number_2 AS (                              -- Indirect co‑stars ONLY
    SELECT PID
    FROM indirect_costars
    WHERE PID NOT IN (SELECT PID FROM shahrukh)      -- not Shahrukh
      AND PID NOT IN (SELECT PID FROM direct_costars) -- never acted directly with him
)
SELECT COUNT(*) AS actors_with_shahrukh_number_2
FROM shahrukh_number_2;