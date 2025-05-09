WITH normalized AS (
  SELECT
    trade_name,
    SAFE_CAST(approval_date AS DATETIME) AS approval_dt,
    -- build a “clean” company string made of only alphanumerics,
    -- dropping common corporate suffixes
    (
      SELECT STRING_AGG(token, '')
      FROM UNNEST(REGEXP_EXTRACT_ALL(LOWER(applicant_full_name), r'[a-z0-9]+')) AS token
      WHERE token NOT IN (
        'inc','llc','ltd','plc','co','corp','corporation',
        'company','limited','us','usa'
      )
    ) AS clean_company
  FROM `bigquery-public-data.ebi_chembl.products_23`
)

SELECT
  trade_name,
  MAX(approval_dt) AS latest_approval_date
FROM normalized
WHERE clean_company = 'sanofiaventis'     -- precise match after normalization
GROUP BY trade_name
ORDER BY latest_approval_date DESC, trade_name;