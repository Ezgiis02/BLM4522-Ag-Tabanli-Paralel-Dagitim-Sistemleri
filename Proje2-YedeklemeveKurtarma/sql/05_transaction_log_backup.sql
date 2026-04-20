-- ================================================
-- PROJE 2: Veritabanı Yedekleme ve Felaketten Kurtarma
-- Adım 5: Transaction Log Backup
-- Veritabanı: Chinook
-- Platform: MS SQL Server (LocalDB)
-- Tarih: Nisan 2026
-- ================================================

USE master;

-- Sorgu 1: Mevcut recovery model kontrol
-- Sonuç: SIMPLE (log backup desteklenmiyor)
SELECT name, recovery_model_desc
FROM sys.databases
WHERE name = 'Chinook';

-- Sorgu 2: Recovery model'i FULL yap ve doğrula
-- Sonuç: FULL (log backup artık destekleniyor)
ALTER DATABASE Chinook SET RECOVERY FULL;

SELECT name, recovery_model_desc
FROM sys.databases
WHERE name = 'Chinook';

-- Sorgu 3: Log backup öncesi tam yedek al (zorunlu)
-- Sonuç: 762 sayfa, 0.018 saniyede işlendi (330.512 MB/sn)
BACKUP DATABASE Chinook
TO DISK = 'C:\Backup\Chinook_Full2.bak'
WITH FORMAT, NAME = 'Chinook Tam Yedek 2';

-- Sorgu 4: Transaction Log Backup al
-- Sonuç: 7 sayfa, 0.003 saniyede işlendi (16.927 MB/sn)
BACKUP LOG Chinook
TO DISK = 'C:\Backup\Chinook_Log.bak'
WITH NAME = 'Chinook Log Yedek';

-- Sorgu 5: Tüm yedek geçmişini görüntüle
-- Sonuç: Log Yedek(0.08MB), Tam Yedek(6.03MB), Diferansiyel(0.78MB), Tam Yedek(6.03MB)
SELECT bs.database_name,
    bs.backup_start_date,
    CASE bs.type
        WHEN 'D' THEN 'Tam Yedek'
        WHEN 'I' THEN 'Diferansiyel'
        WHEN 'L' THEN 'Log Yedek'
    END AS YedekTuru,
    CAST(bs.backup_size/1024.0/1024.0 AS DECIMAL(10,2)) AS BoyutMB,
    bmf.physical_device_name AS DosyaYolu
FROM msdb.dbo.backupset bs
JOIN msdb.dbo.backupmediafamily bmf ON bs.media_set_id = bmf.media_set_id
WHERE bs.database_name = 'Chinook'
ORDER BY bs.backup_start_date DESC;
