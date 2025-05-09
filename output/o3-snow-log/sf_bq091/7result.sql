WITH a61_publications AS (   -- all publications classified in CPC subclass A61
    SELECT DISTINCT
           p."publication_number",
           p."filing_date",
           assignee.value:"name"::string AS assignee_name
    FROM PATENTS.PATENTS.PUBLICATIONS p
         , LATERAL FLATTEN(input => p."cpc")        cpc_code      -- unpack CPC codes
         , LATERAL FLATTEN(input => p."assignee_harmonized") assignee  -- unpack assignees
    WHERE cpc_code.value:"code"::string LIKE 'A61%'              -- keep only A61 codes
      AND p."filing_date" IS NOT NULL                            -- need a filing date
),
top_assignee AS (            -- find the assignee with the most A61 applications
    SELECT assignee_name,
           COUNT(*) AS app_cnt
    FROM a61_publications
    GROUP BY assignee_name
    ORDER BY app_cnt DESC NULLS LAST
    LIMIT 1
),
yearly_counts AS (           -- for that assignee, count applications by filing year
    SELECT EXTRACT(year FROM TO_DATE("filing_date"::string,'YYYYMMDD')) AS filing_year,
           COUNT(*) AS app_cnt
    FROM a61_publications
    WHERE assignee_name = (SELECT assignee_name FROM top_assignee)
    GROUP BY filing_year
)
-- year with the highest number of filings for the top assignee
SELECT filing_year
FROM yearly_counts
ORDER BY app_cnt DESC NULLS LAST
LIMIT 1;