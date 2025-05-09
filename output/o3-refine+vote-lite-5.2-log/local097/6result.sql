WITH start_years AS (
    SELECT DISTINCT CAST(year AS INTEGER) AS start_year
    FROM Movie
    WHERE year GLOB '[0-9]*'          -- keep only numeric years
)
SELECT
    s.start_year,
    COUNT(*) AS total_count
FROM start_years AS s
JOIN Movie AS m
  ON CAST(m.year AS INTEGER) BETWEEN s.start_year AND s.start_year + 9
GROUP BY s.start_year
ORDER BY total_count DESC, s.start_year        -- in case of ties, earliest start year first
LIMIT 1;