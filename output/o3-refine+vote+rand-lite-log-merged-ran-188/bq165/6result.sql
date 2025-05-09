/*  Frequency of copy-number categories per cytogenetic band
    in breast cancer (morph = 3111) and adenocarcinoma (topo = 0401)          */

WITH
/*---------------------------------------------------------------------------
  1)  Cohort – all (RefNo,CaseNo) pairs that belong to the requested entities
----------------------------------------------------------------------------*/
cohort AS (
  SELECT DISTINCT RefNo , CaseNo
  FROM   `mitelman-db.prod.Cytogen`
  WHERE  Morph = '3111'      -- breast cancer
     OR  Topo  = '0401'      -- adenocarcinoma
),

/*---------------------------------------------------------------------------
  2)  All clones from the CytoConverter output that belong to the cohort.
      We will use the number of unique clones as the denominator for
      frequency calculations.
----------------------------------------------------------------------------*/
cohort_clones AS (
  SELECT DISTINCT
         cc.RefNo, cc.CaseNo, cc.InvNo, cc.Clone,
         CONCAT(cc.RefNo,'|',cc.CaseNo,'|',cc.InvNo,'|',cc.Clone) AS clone_id
  FROM   `mitelman-db.prod.CytoConverted` cc
  JOIN   cohort USING (RefNo,CaseNo)
),

tot_clones AS ( SELECT COUNT(*) AS n_clones FROM cohort_clones ),

/*---------------------------------------------------------------------------
  3)  Map every CytoConverter interval to the cytogenetic band(s) it overlaps.
      Translate the original CytoConverter class (“Type”) into the four
      requested biological categories.
----------------------------------------------------------------------------*/
band_events AS (
  SELECT
      b.cytoband_name,
      b.hg38_start,
      b.hg38_stop,
      /* translate CytoConverter class -> biological category */
      CASE
        WHEN LOWER(cc.Type) IN ('amp','amplification','amplifications')  THEN 'amplifications'
        WHEN LOWER(cc.Type)              = 'gain'                       THEN 'gains'
        WHEN LOWER(cc.Type) IN ('homloss','homdel','homodeletion')      THEN 'homozygous deletions'
        WHEN LOWER(cc.Type)              = 'loss'                       THEN 'losses'
        ELSE 'other'
      END                                                              AS event_class,
      CONCAT(cc.RefNo,'|',cc.CaseNo,'|',cc.InvNo,'|',cc.Clone)          AS clone_id,
      /* chromosome order for final sorting */
      CASE
        WHEN REGEXP_EXTRACT(b.chromosome,r'chr(\d+)') IS NOT NULL
             THEN CAST(REGEXP_EXTRACT(b.chromosome,r'chr(\d+)') AS INT64)
        WHEN b.chromosome = 'chrX' THEN 23
        WHEN b.chromosome = 'chrY' THEN 24
        ELSE 99
      END                                                              AS chr_ord
  FROM   `mitelman-db.prod.CytoConverted`  cc
  JOIN   cohort                         USING (RefNo,CaseNo)
  JOIN   `mitelman-db.prod.CytoBands_hg38` b
         ON  cc.Chr   = b.chromosome
         AND cc.Start < b.hg38_stop      -- overlap
         AND cc.End   > b.hg38_start
)

/*---------------------------------------------------------------------------
  4)  Aggregate per band and compute absolute numbers + percentages
----------------------------------------------------------------------------*/
SELECT
    chr_ord                                   AS ChromOrd,
    cytoband_name                             AS Cytoband,
    hg38_start                                AS BandStart,
    hg38_stop                                 AS BandEnd,

    /* absolute numbers (unique clones) */
    COUNT(DISTINCT IF(event_class='amplifications'      ,clone_id,NULL)) AS n_amplifications,
    COUNT(DISTINCT IF(event_class='gains'               ,clone_id,NULL)) AS n_gains,
    COUNT(DISTINCT IF(event_class='losses'              ,clone_id,NULL)) AS n_losses,
    COUNT(DISTINCT IF(event_class='homozygous deletions',clone_id,NULL)) AS n_homozygous_deletions,

    /* frequencies (%) with two decimals */
    ROUND(100 * COUNT(DISTINCT IF(event_class='amplifications'      ,clone_id,NULL))
              / n_clones, 2)                                             AS freq_amplifications_pct,
    ROUND(100 * COUNT(DISTINCT IF(event_class='gains'               ,clone_id,NULL))
              / n_clones, 2)                                             AS freq_gains_pct,
    ROUND(100 * COUNT(DISTINCT IF(event_class='losses'              ,clone_id,NULL))
              / n_clones, 2)                                             AS freq_losses_pct,
    ROUND(100 * COUNT(DISTINCT IF(event_class='homozygous deletions',clone_id,NULL))
              / n_clones, 2)                                             AS freq_homozygous_deletions_pct
FROM   band_events, tot_clones
GROUP BY
    ChromOrd, Cytoband, BandStart, BandEnd, n_clones
ORDER BY
    ChromOrd, BandStart, BandEnd;