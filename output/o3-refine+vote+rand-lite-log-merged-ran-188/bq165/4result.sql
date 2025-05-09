/*---------------------------------------------------------------------------
  Chromosomal copy-number event frequencies in breast-cancer (Morph = 3111)
  and adenocarcinoma (Topo = 0401) cohorts.

  – Counts are the number of DISTINCT clones that harbour an event in the
    cytoband (clone = RefNo-CaseNo-InvNo-Clone).
  – Frequencies are percentages of the total number of clones in the cohort,
    rounded to two decimals.
  – Event classes:
        Amplification         : amp / amplification / highgain
        Gain                  : gain               ( +1 copy )
        Loss                  : loss               ( –1 copy )
        HomozygousDeletion    : homdel / homodeletion / deepdeletion ( –2 copies )
---------------------------------------------------------------------------*/
WITH
/* All clones that belong to either breast-cancer or adenocarcinoma cases */
cohort_clones AS (
  SELECT DISTINCT
         CONCAT(CAST(conv.RefNo AS STRING),'|',conv.CaseNo,'|',
                CAST(conv.InvNo AS STRING),'|',CAST(conv.Clone AS STRING)) AS clone_id,
         conv.RefNo,
         conv.CaseNo,
         conv.InvNo,
         conv.Clone
  FROM   `mitelman-db.prod.CytoConverted` AS conv
  JOIN   `mitelman-db.prod.Cytogen`       AS cyt
    ON   conv.RefNo  = cyt.RefNo
   AND   conv.CaseNo = cyt.CaseNo
  WHERE  cyt.Morph = '3111'               -- breast cancer
     OR  cyt.Topo  = '0401'               -- adenocarcinoma
),
/* Map every relevant copy-number event to the cytoband(s) it overlaps */
event_data AS (
  SELECT DISTINCT
         c.clone_id,
         conv.RefNo,
         bands.chromosome,
         conv.ChrOrd                    AS chr_order,
         bands.cytoband_name,
         bands.hg38_start,
         bands.hg38_stop,
         CASE
           WHEN LOWER(conv.Type) IN ('amp','amplification','highgain')
                THEN 'Amplification'
           WHEN LOWER(conv.Type) =  'gain'
                THEN 'Gain'
           WHEN LOWER(conv.Type) IN ('homdel','homodeletion','deepdeletion')
                THEN 'HomozygousDeletion'
           WHEN LOWER(conv.Type) =  'loss'
                THEN 'Loss'
         END                             AS event_class
  FROM   `mitelman-db.prod.CytoConverted`  AS conv
  JOIN   cohort_clones                     AS c
    ON   conv.RefNo = c.RefNo
   AND   conv.CaseNo = c.CaseNo
   AND   conv.InvNo  = c.InvNo
   AND   conv.Clone  = c.Clone
  JOIN   `mitelman-db.prod.CytoBands_hg38` AS bands
    ON   conv.Chr   = bands.chromosome
   AND   conv.Start < bands.hg38_stop      -- interval overlap
   AND   conv.End   > bands.hg38_start
  WHERE  LOWER(conv.Type) IN ('gain','loss','amp','amplification',
                              'highgain','homdel','homodeletion','deepdeletion')
),
/* Aggregate clone-level counts per cytoband and event class */
band_counts AS (
  SELECT
        chr_order,
        chromosome,
        cytoband_name,
        hg38_start,
        hg38_stop,
        COUNT(DISTINCT CASE WHEN event_class = 'Amplification'
                            THEN clone_id END)  AS amplification_cnt,
        COUNT(DISTINCT CASE WHEN event_class = 'Gain'
                            THEN clone_id END)  AS gain_cnt,
        COUNT(DISTINCT CASE WHEN event_class = 'Loss'
                            THEN clone_id END)  AS loss_cnt,
        COUNT(DISTINCT CASE WHEN event_class = 'HomozygousDeletion'
                            THEN clone_id END)  AS homdel_cnt
  FROM  event_data
  GROUP BY chr_order, chromosome, cytoband_name, hg38_start, hg38_stop
),
/* Total number of clones in the cohort (denominator for percentages) */
total AS (
  SELECT COUNT(DISTINCT clone_id) AS n_clones
  FROM   cohort_clones
)

SELECT
  chromosome,
  cytoband_name,
  hg38_start,
  hg38_stop,
  amplification_cnt  AS amplification_number,
  ROUND(100.0 * amplification_cnt / n_clones, 2) AS amplification_freq_pct,
  gain_cnt           AS gain_number,
  ROUND(100.0 * gain_cnt           / n_clones, 2) AS gain_freq_pct,
  loss_cnt           AS loss_number,
  ROUND(100.0 * loss_cnt           / n_clones, 2) AS loss_freq_pct,
  homdel_cnt         AS homdel_number,
  ROUND(100.0 * homdel_cnt         / n_clones, 2) AS homdel_freq_pct
FROM band_counts, total
ORDER BY chr_order, hg38_start, hg38_stop;