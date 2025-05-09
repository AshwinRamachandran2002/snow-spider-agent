WITH top_industry AS (
    -- 1. Find the industry with the most unicorns (valuation ≥ $1 B) in 2019‑2021
    SELECT ind."industry",
           COUNT(*) AS unicorn_cnt
    FROM   "companies_dates"       AS d
    JOIN   "companies_funding"     AS fi  ON d."company_id" = fi."company_id"
    JOIN   "companies_industries"  AS ind ON d."company_id" = ind."company_id"
    WHERE  fi."valuation" >= 1000000000
      AND  substr(d."date_joined",1,4) BETWEEN '2019' AND '2021'
    GROUP  BY ind."industry"
    ORDER  BY unicorn_cnt DESC
    LIMIT 1
),
yearly_counts AS (
    -- 2. Year‑by‑year unicorn counts for that top industry
    SELECT substr(d."date_joined",1,4) AS yr,
           COUNT(*)                    AS cnt
    FROM   "companies_dates"       AS d
    JOIN   "companies_funding"     AS fi  ON d."company_id" = fi."company_id"
    JOIN   "companies_industries"  AS ind ON d."company_id" = ind."company_id"
    JOIN   top_industry            AS t   ON ind."industry" = t."industry"
    WHERE  fi."valuation" >= 1000000000
      AND  substr(d."date_joined",1,4) BETWEEN '2019' AND '2021'
    GROUP  BY yr
)
-- 3. Average yearly count (2019‑2021) for that top industry
SELECT t."industry"                                  AS top_industry,
       AVG(y.cnt)                                    AS avg_unicorns_per_year_2019_2021
FROM   yearly_counts  AS y
JOIN   top_industry   AS t
WHERE  y.yr BETWEEN '2019' AND '2021';