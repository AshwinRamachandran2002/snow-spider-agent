/*  Latest approval date and corresponding trade name for every molecule
    that is linked (via research‑stem mapping) to the company name exactly
    equal to ‘SanofiAventis’ in ChEMBL 23                                          */
WITH company_res_stems AS (   -- 1. company → research‑stem id(s)
  SELECT DISTINCT res_stem_id
  FROM `bigquery-public-data.ebi_chembl.research_companies_23`
  WHERE company = 'SanofiAventis'                     -- exact match
),
company_molecules AS (       -- 2. research‑stem → molecule(s)
  SELECT DISTINCT molregno
  FROM `bigquery-public-data.ebi_chembl.molecule_synonyms_23`
  WHERE res_stem_id IN (SELECT res_stem_id FROM company_res_stems)
),
molecule_products AS (       -- 3. molecule(s) → product(s) with approval dates
  SELECT
    f.molregno,
    p.trade_name,
    SAFE.PARSE_DATE('%Y-%m-%d', SUBSTR(p.approval_date,1,10)) AS approval_dt
  FROM `bigquery-public-data.ebi_chembl.formulations_23` AS f
  JOIN `bigquery-public-data.ebi_chembl.products_23`      AS p
    ON p.product_id = f.product_id
  WHERE f.molregno IN (SELECT molregno FROM company_molecules)
        AND p.approval_date IS NOT NULL
)
SELECT
  molregno,
  ARRAY_AGG(trade_name ORDER BY approval_dt DESC LIMIT 1)[OFFSET(0)]
      AS trade_name,
  MAX(approval_dt) AS latest_approval_date
FROM molecule_products
GROUP BY molregno
ORDER BY latest_approval_date DESC;