/*--------------------------------------------------------------------
  Frequency of chromosomal copy‑number events in
  – breast cancer (Morphology = '3111')
  – adenocarcinoma      (Topography = '0401')
  based on CytoConverter genomic coordinates (hg38).

  For every cytogenetic band we report:
    • number of distinct clones with
        – Amplification  (>1 extra copy)
        – Gain           (1 extra copy)
        – Loss           (1 copy lost)
        – HomDel         (homozygous deletion, 2 copies lost)
    • corresponding frequency in the whole cohort (% with 2 decimals)
--------------------------------------------------------------------*/
WITH cohort_events AS (          -- all CytoConverted rows belonging to the cohort
  SELECT
    cc.RefNo,
    cc.CaseNo,
    cc.InvNo,
    cc.Clone,
    cc.Chr        AS chromosome,
    cc.Start,
    cc.End,
    cc.Type       AS cc_type,
    CONCAT(
      CAST(cc.RefNo AS STRING),'|',cc.CaseNo,'|',
      CAST(cc.InvNo AS STRING),'|',CAST(cc.Clone AS STRING)
    )             AS clone_id            -- unique clone identifier
  FROM `mitelman-db.prod.CytoConverted`   AS cc
  JOIN `mitelman-db.prod.Cytogen`         AS cy
    ON cy.RefNo  = cc.RefNo
   AND cy.CaseNo = cc.CaseNo
  WHERE TRIM(cy.Morph) = '3111'           -- breast cancer
     OR TRIM(cy.Topo)  = '0401'           -- adenocarcinoma
),
band_events AS (                 -- overlap CytoConverted segments with cytobands
  SELECT
    cb.chromosome,
    cb.cytoband_name,
    cb.hg38_start,
    cb.hg38_stop,
    ce.clone_id,
    CASE
      WHEN LOWER(ce.cc_type) LIKE '%amp%'                                   THEN 'Amplification'
      WHEN LOWER(ce.cc_type) LIKE '%gain%'                                  THEN 'Gain'
      WHEN LOWER(ce.cc_type) LIKE '%hom%'                                   THEN 'HomDel'
      WHEN LOWER(ce.cc_type) LIKE '%loss%' OR LOWER(ce.cc_type) LIKE '%del' THEN 'Loss'
    END AS event_category
  FROM cohort_events               AS ce
  JOIN `mitelman-db.prod.CytoBands_hg38` AS cb
    ON cb.chromosome = ce.chromosome
   AND ce.Start < cb.hg38_stop      -- interval overlap
   AND ce.End   > cb.hg38_start
),
total_cohort AS (                -- number of distinct clones in the cohort
  SELECT COUNT(DISTINCT clone_id) AS total_clones
  FROM cohort_events
),
per_band AS (                    -- count distinct clones per band & category
  SELECT
    chromosome,
    cytoband_name,
    hg38_start,
    hg38_stop,
    COUNT(DISTINCT IF(event_category = 'Amplification', clone_id, NULL)) AS amp_count,
    COUNT(DISTINCT IF(event_category = 'Gain',          clone_id, NULL)) AS gain_count,
    COUNT(DISTINCT IF(event_category = 'Loss',          clone_id, NULL)) AS loss_count,
    COUNT(DISTINCT IF(event_category = 'HomDel',        clone_id, NULL)) AS homdel_count
  FROM band_events
  GROUP BY chromosome, cytoband_name, hg38_start, hg38_stop
)
SELECT
  chromosome,
  cytoband_name,
  hg38_start,
  hg38_stop,
  amp_count,
  ROUND(100.0 * amp_count  / total_clones, 2) AS amp_freq_pct,
  gain_count,
  ROUND(100.0 * gain_count / total_clones, 2) AS gain_freq_pct,
  loss_count,
  ROUND(100.0 * loss_count / total_clones, 2) AS loss_freq_pct,
  homdel_count,
  ROUND(100.0 * homdel_count / total_clones, 2) AS homdel_freq_pct
FROM per_band
CROSS JOIN total_cohort           -- to compute percentages
ORDER BY
  CASE                             -- chromosome order: 1‑22, X, Y
    WHEN REGEXP_CONTAINS(chromosome, r'chr(\d+)')
         THEN CAST(REGEXP_EXTRACT(chromosome, r'chr(\d+)') AS INT64)
    WHEN chromosome = 'chrX' THEN 23
    WHEN chromosome = 'chrY' THEN 24
    ELSE 25
  END,
  hg38_start,
  hg38_stop;