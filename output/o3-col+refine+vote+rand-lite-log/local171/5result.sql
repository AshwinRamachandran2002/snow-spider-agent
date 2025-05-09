WITH male_la AS (
    -- all male legislators
    SELECT "id_bioguide"
    FROM   "legislators"
    WHERE  "gender" = 'M'
),
first_term AS (
    -- first term-start date for every male Louisiana legislator
    SELECT lt."id_bioguide",
           MIN(lt."term_start") AS "first_start"
    FROM   "legislators_terms" lt
    JOIN   male_la             ml ON ml."id_bioguide" = lt."id_bioguide"
    WHERE  lt."state" = 'LA'
    GROUP BY lt."id_bioguide"
),
dec31 AS (
    -- every December-31 date available
    SELECT "date",
           CAST(strftime('%Y',"date") AS INTEGER) AS yr
    FROM   "legislation_date_dim"
    WHERE  "date" LIKE '%-12-31'
),
active AS (
    -- (legislator × Dec-31) rows while the legislator was in office
    SELECT lt."id_bioguide",
           d.yr
    FROM   "legislators_terms" lt
    JOIN   dec31              d
           ON lt."term_start" <= d."date"
          AND lt."term_end"   >= d."date"
    WHERE  lt."state" = 'LA'
)
-- final result: number of distinct legislators by years-elapsed bucket
SELECT  (a.yr - CAST(substr(f."first_start",1,4) AS INTEGER)) AS years_elapsed,
        COUNT(DISTINCT a."id_bioguide")                       AS num_legislators
FROM    active      a
JOIN    first_term  f ON f."id_bioguide" = a."id_bioguide"
WHERE   (a.yr - CAST(substr(f."first_start",1,4) AS INTEGER)) > 30
  AND   (a.yr - CAST(substr(f."first_start",1,4) AS INTEGER)) < 50
GROUP BY years_elapsed
ORDER BY years_elapsed;