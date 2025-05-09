WITH first_terms AS (
  SELECT 
    l."id_bioguide",
    l."gender",
    lt."state",
    MIN(TO_DATE(lt."term_start", 'YYYY-MM-DD')) AS "first_term_start"
  FROM CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATORS l
  JOIN CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATORS_TERMS lt 
    ON l."id_bioguide" = lt."id_bioguide"
  GROUP BY l."id_bioguide", l."gender", lt."state"
),
intervals AS (
  SELECT 0 AS interval_index UNION ALL
  SELECT 1 UNION ALL
  SELECT 2 UNION ALL
  SELECT 3 UNION ALL
  SELECT 4
),
legislator_intervals AS (
  SELECT 
    ft."id_bioguide",
    ft."gender",
    ft."state",
    intervals.interval_index,
    DATEADD('year', intervals.interval_index * 2, ft."first_term_start") AS interval_start,
    DATEADD('year', (intervals.interval_index + 1) * 2, ft."first_term_start") AS interval_end
  FROM first_terms ft
  CROSS JOIN intervals
),
served_intervals AS (
  SELECT DISTINCT
    li."state",
    li."gender",
    li.interval_index
  FROM legislator_intervals li
  JOIN CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATORS_TERMS lt 
    ON li."id_bioguide" = lt."id_bioguide"
  WHERE 
    TO_DATE(lt."term_end", 'YYYY-MM-DD') > li.interval_start
    AND TO_DATE(lt."term_start", 'YYYY-MM-DD') < li.interval_end
),
state_gender_interval_counts AS (
  SELECT 
    sgi."state",
    sgi."gender",
    COUNT(DISTINCT sgi.interval_index) AS intervals_with_service
  FROM served_intervals sgi
  GROUP BY sgi."state", sgi."gender"
),
states_meeting_condition AS (
  SELECT sgi."state"
  FROM state_gender_interval_counts sgi
  WHERE sgi.intervals_with_service = 5
  GROUP BY sgi."state"
  HAVING COUNT(DISTINCT sgi."gender") = 2
)
SELECT DISTINCT "state"
FROM states_meeting_condition;