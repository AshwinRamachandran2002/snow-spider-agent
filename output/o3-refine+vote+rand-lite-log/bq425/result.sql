/*  Most‑recent approval for every molecule that is linked to the
    company name exactly equal to “SanofiAventis” in ChEMBL 23.        */

WITH company_res_stems AS (          -- 1.  SanofiAventis research stems
  SELECT DISTINCT res_stem_id
  FROM `bigquery-public-data.ebi_chembl.research_companies_23`
  WHERE company = 'SanofiAventis'
),

company_molecules AS (               -- 2.  Molecules that carry those stems
  SELECT DISTINCT molregno
  FROM `bigquery-public-data.ebi_chembl.molecule_synonyms_23`
  WHERE res_stem_id IN (SELECT res_stem_id FROM company_res_stems)
),

molecule_products AS (               -- 3.  Trade names + approval dates
  SELECT
    f.molregno,
    p.trade_name,
    DATE(p.approval_date) AS approval_date
  FROM           company_molecules                                   AS cm
  JOIN `bigquery-public-data.ebi_chembl.formulations_23`             AS f
        ON cm.molregno = f.molregno
  JOIN `bigquery-public-data.ebi_chembl.products_23`                 AS p
        ON f.product_id = p.product_id
  WHERE p.approval_date IS NOT NULL
),

latest_per_molecule AS (             -- 4.  Keep latest approval per molecule
  SELECT
    mp.molregno,
    mp.trade_name,
    mp.approval_date,
    ROW_NUMBER() OVER (PARTITION BY mp.molregno ORDER BY mp.approval_date DESC) AS rn
  FROM molecule_products AS mp
)

SELECT
  m.chembl_id,
  l.trade_name,
  l.approval_date AS latest_approval_date
FROM       latest_per_molecule                      AS l
JOIN `bigquery-public-data.ebi_chembl.molecule_dictionary_23` AS m
      ON l.molregno = m.molregno
WHERE l.rn = 1
ORDER BY m.chembl_id;