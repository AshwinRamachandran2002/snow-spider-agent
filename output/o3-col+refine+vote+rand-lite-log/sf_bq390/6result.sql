-- Distinct studies in “qin_prostate_repeatability” that have
-- (1) axial T2-weighted MR series and
-- (2) segmentations of the Peripheral zone
SELECT DISTINCT
       t2."StudyInstanceUID"
FROM (
        /* studies with axial T2-weighted MR imaging */
        SELECT DISTINCT "StudyInstanceUID"
        FROM IDC.IDC_V17.DICOM_ALL
        WHERE "collection_id" = 'qin_prostate_repeatability'
          AND "Modality" = 'MR'
          AND "SeriesDescription" ILIKE '%T2%'
          AND "SeriesDescription" ILIKE '%AX%'
     ) AS t2
JOIN (
        /* studies that contain Peripheral-zone segmentations */
        SELECT DISTINCT da."StudyInstanceUID"
        FROM IDC.IDC_V17.SEGMENTATIONS AS s
        JOIN IDC.IDC_V17.DICOM_ALL  AS da
          ON da."SeriesInstanceUID" = s."segmented_SeriesInstanceUID"
        WHERE da."collection_id" = 'qin_prostate_repeatability'
          AND s."SegmentedPropertyType" ILIKE '%Peripheral%zone%'
     ) AS seg
  ON t2."StudyInstanceUID" = seg."StudyInstanceUID";