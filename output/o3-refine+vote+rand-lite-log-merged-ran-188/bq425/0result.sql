/*  ChEMBL Release 23  
    Distinct molecules whose applicant name reduces exactly to “SanofiAventis”.
    1.  Strip common corporate qualifiers (US, LLC, INC …) from applicant name.  
    2.  Remove any non-alphabetic characters and compare to “SANOFIAVENTIS”.  
    3.  Keep only the most recent FDA approval date per trade name.            */
WITH normalised AS (
  SELECT
    trade_name,
    SAFE.PARSE_DATE('%F', SUBSTR(approval_date, 1, 10)) AS approval_dt,
    -- Upper-case, drop frequent suffixes, then delete everything non-A–Z
    REGEXP_REPLACE(
      REGEXP_REPLACE(UPPER(applicant_full_name),
                     r'\b(US|LLC|INC|LTD|LP|CO|CORPORATION|CORP)\b',
                     ''
      ),
      r'[^A-Z]',
      ''
    ) AS cleaned_name
  FROM `bigquery-public-data.ebi_chembl.products_23`
)

SELECT
  trade_name,
  MAX(approval_dt) AS latest_approval_date
FROM normalised
WHERE cleaned_name = 'SANOFIAVENTIS'
  AND approval_dt IS NOT NULL
GROUP BY trade_name
ORDER BY latest_approval_date DESC;