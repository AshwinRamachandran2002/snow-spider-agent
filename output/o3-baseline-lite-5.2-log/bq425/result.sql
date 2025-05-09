WITH company_res_stems AS (
  SELECT DISTINCT res_stem_id
  FROM `bigquery-public-data.ebi_chembl.research_companies_23`
  WHERE company = 'SanofiAventis'          -- exact match
),
molecule_list AS (
  SELECT DISTINCT ms.molregno
  FROM `bigquery-public-data.ebi_chembl.molecule_synonyms_23` ms
  JOIN company_res_stems USING (res_stem_id)
),
molecule_products AS (
  SELECT
    f.molregno,
    p.trade_name,
    p.approval_date
  FROM `bigquery-public-data.ebi_chembl.formulations_23`  f
  JOIN `bigquery-public-data.ebi_chembl.products_23`      p
    USING (product_id)
  JOIN molecule_list ml
    ON ml.molregno = f.molregno
  WHERE p.trade_name IS NOT NULL
)
, ranked AS (
  SELECT
    molregno,
    trade_name,
    approval_date,
    ROW_NUMBER() OVER (
        PARTITION BY molregno
        ORDER BY approval_date DESC
    ) AS rn
  FROM molecule_products
)
SELECT
  molregno,
  trade_name,
  approval_date   AS most_recent_approval_date
FROM ranked
WHERE rn = 1
ORDER BY most_recent_approval_date DESC;