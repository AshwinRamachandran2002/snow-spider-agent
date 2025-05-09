-- ChEMBL 23 – molecules linked to the company name exactly “SanofiAventis”
WITH company_stems AS (
  SELECT DISTINCT res_stem_id
  FROM `bigquery-public-data.ebi_chembl.research_companies_23`
  WHERE company = 'SanofiAventis'               -- exact match
),
company_molecules AS (
  SELECT DISTINCT ms.molregno
  FROM `bigquery-public-data.ebi_chembl.molecule_synonyms_23` AS ms
  JOIN company_stems USING (res_stem_id)
),
product_dates AS (
  SELECT
    cm.molregno,
    pr.trade_name,
    SAFE_CAST(pr.approval_date AS DATE) AS approval_date
  FROM company_molecules                 AS cm
  JOIN `bigquery-public-data.ebi_chembl.formulations_23` AS fm
    ON cm.molregno = fm.molregno
  JOIN `bigquery-public-data.ebi_chembl.products_23`      AS pr
    ON fm.product_id = pr.product_id
  WHERE pr.approval_date IS NOT NULL
),
latest_per_molecule AS (
  SELECT
    molregno,
    trade_name,
    approval_date,
    ROW_NUMBER() OVER (
      PARTITION BY molregno
      ORDER BY approval_date DESC, trade_name
    ) AS rn
  FROM product_dates
)

SELECT
  molregno,
  trade_name,
  approval_date AS most_recent_approval_date
FROM latest_per_molecule
WHERE rn = 1
ORDER BY molregno;