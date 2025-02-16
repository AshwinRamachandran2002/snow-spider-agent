-- Task: Find the list of actors who have worked with Yash Chopra, along with the number of movies they've done together.

WITH YASH_CHOPRAS_PID AS (
    SELECT
        TRIM(P.PID) AS PID
    FROM
        Person P
    WHERE
        TRIM(P.Name) = 'Yash Chopra'
),
ACTORS_WITH_YC AS (
    SELECT
        TRIM(MC.PID) AS ACTOR_PID,
        COUNT(DISTINCT TRIM(MC.MID)) AS NUM_OF_MOV
    FROM
        M_Cast MC
    JOIN
        M_Director MD ON TRIM(MC.MID) = TRIM(MD.MID)
    JOIN
        YASH_CHOPRAS_PID YCP ON TRIM(MD.PID) = YCP.PID
    GROUP BY
        ACTOR_PID
)
SELECT
    P.Name AS Actor_Name,
    A.NUM_OF_MOV
FROM
    ACTORS_WITH_YC A
JOIN
    Person P ON TRIM(A.ACTOR_PID) = TRIM(P.PID)
ORDER BY
    A.NUM_OF_MOV DESC;