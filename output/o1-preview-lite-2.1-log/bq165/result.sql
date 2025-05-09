WITH CohortSamples AS (
    SELECT DISTINCT RefNo, CaseNo
    FROM `mitelman-db.prod.Cytogen`
    WHERE Morph = '3111' OR Topo = '0401'
),
TotalSamples AS (
    SELECT COUNT(*) AS total_samples FROM CohortSamples
),
CytoChanges AS (
    SELECT a.RefNo, a.CaseNo, a.Chr, a.Start, a.End, a.Type
    FROM `mitelman-db.prod.CytoConverted` AS a
    JOIN CohortSamples AS b
        ON a.RefNo = b.RefNo AND a.CaseNo = b.CaseNo
    WHERE a.Type IS NOT NULL
),
BandChanges AS (
    SELECT
        c.RefNo,
        c.CaseNo,
        c.Chr,
        c.Type,
        b.cytoband_name AS Band_name,
        b.hg38_start AS Band_start,
        b.hg38_stop AS Band_end,
        CONCAT(c.RefNo, '_', c.CaseNo) AS sample_id
    FROM CytoChanges c
    JOIN `mitelman-db.prod.CytoBands_hg38` b
        ON c.Chr = b.chromosome
        AND c.Start <= b.hg38_stop
        AND c.End >= b.hg38_start
),
BandSampleCounts AS (
    SELECT
        b.Chr,
        b.Band_name,
        b.Band_start,
        b.Band_end,
        b.sample_id,
        SUM(CASE WHEN b.Type = 'Gain' THEN 1 ELSE 0 END) AS gain_count,
        SUM(CASE WHEN b.Type = 'Loss' THEN 1 ELSE 0 END) AS loss_count
    FROM BandChanges b
    GROUP BY b.Chr, b.Band_name, b.Band_start, b.Band_end, b.sample_id
),
BandSampleCategories AS (
    SELECT
        *,
        CASE
            WHEN gain_count > 1 THEN 'Amplification'
            WHEN gain_count = 1 THEN 'Gain'
            ELSE NULL
        END AS gain_category,
        CASE
            WHEN loss_count > 1 THEN 'HomozygousDeletion'
            WHEN loss_count = 1 THEN 'Loss'
            ELSE NULL
        END AS loss_category
    FROM BandSampleCounts
)
SELECT
    bsc.Chr AS Chromosome,
    bsc.Band_name,
    bsc.Band_start,
    bsc.Band_end,
    COUNT(DISTINCT CASE WHEN bsc.gain_category = 'Amplification' THEN bsc.sample_id END) AS Amplifications_number,
    ROUND(100 * COUNT(DISTINCT CASE WHEN bsc.gain_category = 'Amplification' THEN bsc.sample_id END) / t.total_samples, 2) AS Amplifications_frequency,
    COUNT(DISTINCT CASE WHEN bsc.gain_category = 'Gain' THEN bsc.sample_id END) AS Gains_number,
    ROUND(100 * COUNT(DISTINCT CASE WHEN bsc.gain_category = 'Gain' THEN bsc.sample_id END) / t.total_samples, 2) AS Gains_frequency,
    COUNT(DISTINCT CASE WHEN bsc.loss_category = 'Loss' THEN bsc.sample_id END) AS Losses_number,
    ROUND(100 * COUNT(DISTINCT CASE WHEN bsc.loss_category = 'Loss' THEN bsc.sample_id END) / t.total_samples, 2) AS Losses_frequency,
    COUNT(DISTINCT CASE WHEN bsc.loss_category = 'HomozygousDeletion' THEN bsc.sample_id END) AS HomozygousDeletions_number,
    ROUND(100 * COUNT(DISTINCT CASE WHEN bsc.loss_category = 'HomozygousDeletion' THEN bsc.sample_id END) / t.total_samples, 2) AS HomozygousDeletions_frequency
FROM BandSampleCategories bsc
CROSS JOIN TotalSamples t
GROUP BY bsc.Chr, bsc.Band_name, bsc.Band_start, bsc.Band_end, t.total_samples
ORDER BY
    CASE REPLACE(bsc.Chr, 'chr', '')
        WHEN 'X' THEN 23
        WHEN 'Y' THEN 24
        ELSE CAST(REPLACE(bsc.Chr, 'chr', '') AS INT64)
    END,
    bsc.Band_start,
    bsc.Band_end;