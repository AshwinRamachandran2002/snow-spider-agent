WITH
-- first term (cohort) information for every legislator
first_term AS (
    SELECT
        l."id_bioguide",
        UPPER(l."gender")            AS gender,
        MIN(DATE(lt."term_start"))   AS first_start,
        -- state in which the very first term began
        (SELECT lt2."state"
         FROM   legislators_terms lt2
         WHERE  lt2."id_bioguide" = l."id_bioguide"
         ORDER BY DATE(lt2."term_start")
         LIMIT 1)                    AS state
    FROM legislators l
    JOIN legislators_terms lt
         ON l."id_bioguide" = lt."id_bioguide"
    WHERE UPPER(l."gender") IN ('M','F')
    GROUP BY l."id_bioguide"
),
-- six required time‑offsets (years after the first term’s start year)
offsets(o) AS (
    VALUES (0),(2),(4),(6),(8),(10)
),
-- for every legislator & offset, flag whether the legislator is still
-- serving on 31‑Dec of the (start_year + offset)
retention AS (
    SELECT
        ft.state,
        ft.gender,
        o.o                     AS offset_years,
        COUNT(*)                AS still_serving           -- >0 ⇒ retained
    FROM first_term ft
    JOIN offsets o
    JOIN legislators_terms lt2
         ON lt2."id_bioguide" = ft."id_bioguide"
        -- build the “check date” = 31‑Dec of (start_year + offset)
        AND DATE(lt2."term_start") <= DATE(
                printf('%04d-12-31',
                       CAST(strftime('%Y', ft.first_start) AS INTEGER) + o.o)
            )
        AND DATE(COALESCE(lt2."term_end", '9999-12-31')) >= DATE(
                printf('%04d-12-31',
                       CAST(strftime('%Y', ft.first_start) AS INTEGER) + o.o)
            )
    GROUP BY ft.state, ft.gender, o.o
),
-- states where *each* gender keeps a non‑zero retention at all 6 checkpoints
gender_ok AS (
    SELECT
        state,
        gender
    FROM retention
    WHERE still_serving > 0                -- non‑zero retention
    GROUP BY state, gender
    HAVING COUNT(DISTINCT offset_years) = 6 -- all six checkpoints present
)
SELECT DISTINCT g1.state
FROM gender_ok g1
JOIN gender_ok g2
  ON g1.state = g2.state
 WHERE g1.gender = 'M'
   AND g2.gender = 'F'
ORDER BY g1.state;