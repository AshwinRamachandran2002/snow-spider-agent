/*  ChEMBL 23 – molecules linked to the company exactly named
    “SanofiAventis” (as stored in research_companies.company).
    For every such molecule return the trade‑name having the
    most‑recent product approval date.                                   */

WITH sanofi_res_stems AS (        -- research‑stem IDs owned by SanofiAventis
  SELECT DISTINCT res_stem_id
  FROM `bigquery-public-data.ebi_chembl.research_companies_23`
  WHERE company = 'SanofiAventis'           -- exact match
),

sanofi_molecules AS (             -- molecules associated with those stems
  SELECT DISTINCT ms.molregno
  FROM `bigquery-public-data.ebi_chembl.molecule_synonyms_23` AS ms
  WHERE ms.res_stem_id IN (SELECT res_stem_id FROM sanofi_res_stems)
),

prod_dates AS (                   -- all product approvals for those molecules
  SELECT
    f.molregno,
    p.trade_name,
    DATE(p.approval_date) AS approval_dt
  FROM `bigquery-public-data.ebi_chembl.formulations_23` AS f
  JOIN `bigquery-public-data.ebi_chembl.products_23`     AS p
        ON p.product_id = f.product_id
  WHERE f.molregno IN (SELECT molregno FROM sanofi_molecules)
    AND p.approval_date IS NOT NULL
),

latest_per_molecule AS (          -- keep latest approval per molecule
  SELECT
    molregno,
    ARRAY_AGG(STRUCT(trade_name, approval_dt)
              ORDER BY approval_dt DESC
              LIMIT 1)[OFFSET(0)] AS latest_info
  FROM prod_dates
  GROUP BY molregno
)

SELECT
  m.chembl_id,
  li.trade_name,
  li.approval_dt AS latest_approval_date
FROM latest_per_molecule AS t
JOIN `bigquery-public-data.ebi_chembl.molecule_dictionary_23` AS m
  ON m.molregno = t.molregno
CROSS JOIN UNNEST([t.latest_info]) AS li
ORDER BY li.approval_dt DESC;