/*  Distinct StudyInstanceUIDs in the QIN-Prostate-Repeatability collection that
    (1) include at least one T2-weighted axial MR series and
    (2) contain a segmentation whose SegmentedPropertyType is “Peripheral zone”.
*/
WITH t2_axial_mr_studies AS (
    SELECT DISTINCT "StudyInstanceUID"
    FROM IDC.IDC_V17.DICOM_PIVOT
    WHERE "collection_id" = 'qin_prostate_repeatability'
      AND "Modality" = 'MR'
      AND UPPER("SeriesDescription") LIKE '%T2%'      -- T2-weighted
      AND UPPER("SeriesDescription") LIKE '%AX%'      -- axial orientation
),
peripheral_zone_seg_studies AS (
    SELECT DISTINCT "StudyInstanceUID"
    FROM IDC.IDC_V17.SEGMENTATIONS
    /* SegmentedPropertyType is a VARIANT; cast to VARCHAR and search for the label */
    WHERE TO_VARCHAR("SegmentedPropertyType") ILIKE '%Peripheral zone%'
)
SELECT DISTINCT s."StudyInstanceUID"
FROM t2_axial_mr_studies s
JOIN peripheral_zone_seg_studies p
  ON s."StudyInstanceUID" = p."StudyInstanceUID"
ORDER BY s."StudyInstanceUID";