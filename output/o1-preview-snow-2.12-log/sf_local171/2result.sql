WITH first_terms AS (
  SELECT 
    l."id_bioguide", 
    MIN(TO_DATE(t."term_start", 'YYYY-MM-DD')) AS "first_term_start"
  FROM 
    "CITY_LEGISLATION"."CITY_LEGISLATION"."LEGISLATORS" AS l
  JOIN 
    "CITY_LEGISLATION"."CITY_LEGISLATION"."LEGISLATORS_TERMS" AS t
    ON l."id_bioguide" = t."id_bioguide"
  WHERE 
    l."gender" = 'M' 
    AND t."state" = 'LA'
  GROUP BY 
    l."id_bioguide"
),
years_elapsed AS (
  SELECT 
    31 + ROW_NUMBER() OVER (ORDER BY NULL) - 1 AS "years_elapsed"
  FROM 
    (SELECT 1 FROM (VALUES (1),(1),(1),(1),(1),(1),(1),(1),(1),(1),
                          (1),(1),(1),(1),(1),(1),(1),(1),(1)) AS t(n)
    ) AS nums
),
dec31_dates AS (
  SELECT 
    ft."id_bioguide", 
    ye."years_elapsed", 
    DATE_FROM_PARTS(
      YEAR(DATEADD('year', ye."years_elapsed", ft."first_term_start")), 
      12, 
      31
    ) AS "dec31_date"
  FROM 
    first_terms AS ft
  CROSS JOIN 
    years_elapsed AS ye
),
service_dates AS (
  SELECT 
    dd."id_bioguide", 
    dd."years_elapsed", 
    dd."dec31_date"
  FROM 
    dec31_dates AS dd
  JOIN 
    "CITY_LEGISLATION"."CITY_LEGISLATION"."LEGISLATORS_TERMS" AS t2
    ON dd."id_bioguide" = t2."id_bioguide"
    AND dd."dec31_date" BETWEEN TO_DATE(t2."term_start", 'YYYY-MM-DD') AND TO_DATE(t2."term_end", 'YYYY-MM-DD')
)
SELECT 
  sd."years_elapsed" AS "Years_Elapsed", 
  COUNT(DISTINCT sd."id_bioguide") AS "Number_of_Distinct_Legislators"
FROM 
  service_dates AS sd
GROUP BY 
  sd."years_elapsed"
ORDER BY
  sd."years_elapsed";