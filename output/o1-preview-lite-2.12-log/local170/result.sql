WITH intervals AS (
    SELECT 0 AS interval_years UNION ALL
    SELECT 2 UNION ALL
    SELECT 4 UNION ALL
    SELECT 6 UNION ALL
    SELECT 8 UNION ALL
    SELECT 10
),
initial_terms AS (
    SELECT lt.id_bioguide,
           lt."state",
           MIN(DATE(lt."term_start")) AS initial_term_start,
           l."gender"
    FROM "legislators_terms" lt
    JOIN "legislators" l ON lt.id_bioguide = l.id_bioguide
    GROUP BY lt.id_bioguide, lt."state", l."gender"
),
checkpoints AS (
    SELECT it.id_bioguide,
           it."state",
           it."gender",
           i.interval_years,
           DATE(it.initial_term_start, '+' || i.interval_years || ' years') AS checkpoint_date
    FROM initial_terms it
    CROSS JOIN intervals i
),
service_status AS (
    SELECT c.id_bioguide,
           c."state",
           c."gender",
           c.interval_years,
           CASE WHEN EXISTS (
               SELECT 1 FROM "legislators_terms" lt
               WHERE lt.id_bioguide = c.id_bioguide
                 AND DATE(lt."term_start") <= c.checkpoint_date
                 AND DATE(lt."term_end") >= c.checkpoint_date
           ) THEN 1 ELSE 0 END AS is_serving
    FROM checkpoints c
),
state_gender_intervals AS (
    SELECT ss."state",
           ss."gender",
           ss.interval_years,
           MAX(ss.is_serving) AS serving_at_interval
    FROM service_status ss
    GROUP BY ss."state", ss."gender", ss.interval_years
),
state_gender_summary AS (
    SELECT sgi."state",
           sgi."gender",
           COUNT(*) AS total_intervals,
           SUM(sgi.serving_at_interval) AS intervals_with_serving
    FROM state_gender_intervals sgi
    GROUP BY sgi."state", sgi."gender"
),
states_with_full_retention AS (
    SELECT sgs."state", sgs."gender"
    FROM state_gender_summary sgs
    WHERE sgs.total_intervals = 6
      AND sgs.intervals_with_serving = 6
),
states_with_both_genders AS (
    SELECT s."state"
    FROM states_with_full_retention s
    GROUP BY s."state"
    HAVING COUNT(DISTINCT s."gender") = 2
)
SELECT s."state" AS State_Abbreviation
FROM states_with_both_genders s;