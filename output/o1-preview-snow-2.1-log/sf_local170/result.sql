WITH first_terms AS (
  SELECT 
    l."id_bioguide", 
    l."gender", 
    t."state",
    MIN(TRY_TO_DATE(t."term_start", 'YYYY-MM-DD')) AS "first_term_start"
  FROM 
    "CITY_LEGISLATION"."CITY_LEGISLATION"."LEGISLATORS" l
    JOIN "CITY_LEGISLATION"."CITY_LEGISLATION"."LEGISLATORS_TERMS" t
      ON l."id_bioguide" = t."id_bioguide"
  WHERE 
    l."gender" IN ('M', 'F') AND
    t."term_start" IS NOT NULL AND 
    TRY_TO_DATE(t."term_start", 'YYYY-MM-DD') IS NOT NULL AND
    t."state" IS NOT NULL AND t."state" <> ''
  GROUP BY 
    l."id_bioguide", l."gender", t."state"
),
interval_numbers AS (
  SELECT 0 AS "interval_number" UNION ALL
  SELECT 1 UNION ALL
  SELECT 2 UNION ALL
  SELECT 3 UNION ALL
  SELECT 4
),
intervals AS (
  SELECT 
    ft."id_bioguide", 
    ft."gender", 
    ft."state", 
    ft."first_term_start",
    n."interval_number",
    DATEADD('year', n."interval_number" * 2, ft."first_term_start") AS "interval_start",
    DATEADD('year', (n."interval_number" + 1) * 2, ft."first_term_start") AS "interval_end"
  FROM 
    first_terms ft
    CROSS JOIN interval_numbers n
),
terms AS (
  SELECT 
    l."id_bioguide", 
    l."gender", 
    t."state",
    TRY_TO_DATE(t."term_start", 'YYYY-MM-DD') AS "term_start",
    TRY_TO_DATE(t."term_end", 'YYYY-MM-DD') AS "term_end"
  FROM 
    "CITY_LEGISLATION"."CITY_LEGISLATION"."LEGISLATORS" l
    JOIN "CITY_LEGISLATION"."CITY_LEGISLATION"."LEGISLATORS_TERMS" t
      ON l."id_bioguide" = t."id_bioguide"
  WHERE 
    l."gender" IN ('M', 'F') AND
    t."term_start" IS NOT NULL AND 
    t."term_end" IS NOT NULL AND
    TRY_TO_DATE(t."term_start", 'YYYY-MM-DD') IS NOT NULL AND
    TRY_TO_DATE(t."term_end", 'YYYY-MM-DD') IS NOT NULL AND
    t."state" IS NOT NULL AND t."state" <> ''
),
interval_terms AS (
  SELECT 
    i."state",
    i."gender",
    i."interval_number",
    COUNT(DISTINCT i."id_bioguide") AS "legislators_in_interval"
  FROM 
    intervals i
    JOIN terms t
      ON i."id_bioguide" = t."id_bioguide" AND
         t."term_end" > i."interval_start" AND
         t."term_start" < i."interval_end"
  GROUP BY 
    i."state", i."gender", i."interval_number"
),
state_intervals AS (
  SELECT 
    "state", 
    "gender",
    COUNT(*) AS "intervals_with_service"
  FROM 
    interval_terms
  GROUP BY 
    "state", "gender"
),
states_with_full_coverage AS (
  SELECT 
    "state"
  FROM 
    state_intervals
  WHERE 
    "intervals_with_service" = 5  -- All intervals have service
  GROUP BY 
    "state"
  HAVING 
    COUNT(DISTINCT "gender") = 2  -- Both genders
)
SELECT 
  "state"
FROM 
  states_with_full_coverage;