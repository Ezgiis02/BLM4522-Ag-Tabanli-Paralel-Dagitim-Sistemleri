-- ================================================
-- PROJE 2: Veritabanı Yedekleme ve Felaketten Kurtarma
-- Adım 2: Tam Yedekleme (Full Backup)
-- Veritabanı: Chinook
-- Platform: MS SQL Server (LocalDB)
-- Tarih: Nisan 2026
-- ================================================

USE master;

-- Sorgu 1: Tam yedekleme al
-- Sonuç: 762 sayfa işlendi, 0.030 saniyede tamamlandı (198.307 MB/sn)
BACKUP DATABASE Chinook
TO DISK = 'C:\Backup\Chinook_Full.bak'
WITH FORMAT,
     NAME = 'Chinook Tam Yedek',
     DESCRIPTION = 'Chinook veritabani tam yedekleme';

-- Sorgu 2: Yedek dosyasını doğrula
-- Sonuç: "The backup set on file 1 is valid."
RESTORE VERIFYONLY
FROM DISK = 'C:\Backup\Chinook_Full.bak';
