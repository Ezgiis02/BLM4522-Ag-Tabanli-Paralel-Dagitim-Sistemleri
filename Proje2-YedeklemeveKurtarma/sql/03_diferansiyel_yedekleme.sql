-- ================================================
-- PROJE 2: Veritabanı Yedekleme ve Felaketten Kurtarma
-- Adım 3: Diferansiyel Yedekleme
-- Veritabanı: Chinook
-- Platform: MS SQL Server (LocalDB)
-- Tarih: Nisan 2026
-- ================================================

USE Chinook;

-- Sorgu 1: Diferansiyel yedek öncesi değişiklik yap
-- Genre tablosuna 2 yeni kayıt eklendi
-- Sonuç: Genre tablosu 25 → 27 kayıt
INSERT INTO Genre (GenreId, Name) VALUES (26, 'Jazz Fusion');
INSERT INTO Genre (GenreId, Name) VALUES (27, 'Ambient');

SELECT * FROM Genre;

-- Sorgu 2: Diferansiyel yedek al
-- Sonuç: 90 sayfa işlendi, 0.007 saniyede tamamlandı (99.888 MB/sn)
USE master;

BACKUP DATABASE Chinook
TO DISK = 'C:\Backup\Chinook_Diff.bak'
WITH DIFFERENTIAL,
     NAME = 'Chinook Diferansiyel Yedek',
     DESCRIPTION = 'Chinook veritabani diferansiyel yedekleme';

-- Sorgu 3: Yedek geçmişini görüntüle
-- Sonuç: Chinook_Diff.bak (I=Differential, 0.78MB) ve Chinook_Full.bak (D=Full, 6.03MB)
SELECT
    bs.database_name,
    bs.backup_start_date,
    bs.backup_finish_date,
    bs.type AS YedekTuru,
    CAST(bs.backup_size / 1024.0 / 1024.0 AS DECIMAL(10,2)) AS BoyutMB,
    bmf.physical_device_name AS DosyaYolu
FROM msdb.dbo.backupset bs
JOIN msdb.dbo.backupmediafamily bmf ON bs.media_set_id = bmf.media_set_id
WHERE bs.database_name = 'Chinook'
ORDER BY bs.backup_start_date DESC;
