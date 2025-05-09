WITH company_res AS (   -- res_stem_id linked to the exact company name
  SELECT DISTINCT
    rc.res_stem_id
  FROM
    `bigquery-public-data.ebi_chembl.research_companies_23` rc
  WHERE
    rc.company = 'SanofiAventis'                -- exact match, case‑sensitive
),
company_molecules AS (  -- molecules owned by that company
  SELECT DISTINCT
    ms.molregno
  FROM
    `bigquery-public-data.ebi_chembl.molecule_synonyms_23` ms
  JOIN
    company_res cr
  ON
    ms.res_stem_id = cr.res_stem_id
),
company_products AS (   -- products (trade names + dates) for those molecules
  SELECT
    f.molregno,
    p.trade_name,
    DATE(p.approval_date) AS approval_date
  FROM
    `bigquery-public-data.ebi_chembl.formulations_23`    AS f
  JOIN
    `bigquery-public-data.ebi_chembl.products_23`        AS p
  ON
    p.product_id = f.product_id
  JOIN
    company_molecules cm
  ON
    cm.molregno = f.molregno
  WHERE
    p.approval_date IS NOT NULL                          -- keep only dated approvals
),
latest_per_molecule AS (   -- keep the most recent approval per molecule
  SELECT
    molregno,
    trade_name,
    approval_date,
    ROW_NUMBER() OVER (PARTITION BY molregno
                       ORDER BY approval_date DESC, trade_name) AS rn
  FROM
    company_products
)
SELECT
  molregno,
  trade_name,
  approval_date
FROM
  latest_per_molecule
WHERE
  rn = 1                               -- latest approval date per molecule
ORDER BY
  approval_date DESC;