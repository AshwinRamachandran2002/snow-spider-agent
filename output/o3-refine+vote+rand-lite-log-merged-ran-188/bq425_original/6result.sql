-- Molecules (ChEMBL 23) whose research stem belongs to the company
-- “SanofiAventis”, linked to marketed products; keep the latest
-- approval date per molecule.
WITH sanofi_res_stem AS (
  SELECT DISTINCT res_stem_id
  FROM `bigquery-public-data.ebi_chembl.research_companies_23`
  WHERE company = 'SanofiAventis'
),
sanofi_molecules AS (
  SELECT DISTINCT ms.molregno
  FROM `bigquery-public-data.ebi_chembl.molecule_synonyms_23` AS ms
  JOIN sanofi_res_stem AS r
    ON ms.res_stem_id = r.res_stem_id
),
mol_products AS (
  SELECT
    f.molregno,
    p.trade_name,
    DATE(p.approval_date) AS approval_date
  FROM `bigquery-public-data.ebi_chembl.formulations_23` AS f
  JOIN `bigquery-public-data.ebi_chembl.products_23`     AS p
    ON f.product_id = p.product_id
  JOIN sanofi_molecules                                  AS m
    ON m.molregno = f.molregno
  WHERE p.trade_name IS NOT NULL
)
, ranked AS (
  SELECT
    molregno,
    trade_name,
    approval_date,
    ROW_NUMBER() OVER (PARTITION BY molregno
                       ORDER BY approval_date DESC, trade_name) AS rn
  FROM mol_products
  WHERE approval_date IS NOT NULL
)
SELECT
  trade_name,
  approval_date
FROM ranked
WHERE rn = 1
ORDER BY approval_date DESC, trade_name;