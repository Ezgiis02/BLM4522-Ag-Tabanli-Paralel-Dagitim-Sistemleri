-- ================================================
-- PROJE 2: Veritabanı Yedekleme ve Felaketten Kurtarma
-- Adım 6: Felaketten Kurtarma Senaryosu
-- Veritabanı: Chinook
-- Platform: MS SQL Server (LocalDB)
-- Tarih: Nisan 2026
-- ================================================

USE Chinook;

-- Sorgu 1: Felaket simülasyonu - veri kazara silindi
-- Önce: 27 kayıt | Sonra: 25 kayıt
SELECT COUNT(*) AS GenreSayisi FROM Genre;

DELETE FROM Genre WHERE GenreId IN (26, 27);

SELECT COUNT(*) AS GenreSayisi FROM Genre;

-- Sorgu 2: İlk kurtarma denemesi - Chinook_Restored yetersiz
-- Chinook_Restored ilk tam yedekten geri yüklendi (Jazz Fusion ve Ambient yok)
-- Sonuç: Boş sonuç - kurtarma başarısız
USE master;

SELECT * FROM Chinook_Restored.dbo.Genre WHERE GenreId IN (26, 27);

INSERT INTO Chinook.dbo.Genre (GenreId, Name)
SELECT GenreId, Name FROM Chinook_Restored.dbo.Genre
WHERE GenreId IN (26, 27);

-- Sorgu 3: Doğru yedekten kurtarma - Chinook_Full2.bak kullan
-- Chinook_Full2.bak Jazz Fusion ve Ambient eklendikten SONRA alındı
-- Sonuç: 762 sayfa, 0.019 saniyede geri yüklendi
RESTORE DATABASE Chinook_Recovery
FROM DISK = 'C:\Backup\Chinook_Full2.bak'
WITH MOVE 'Chinook' TO 'C:\Backup\Chinook_Recovery.mdf',
     MOVE 'Chinook_log' TO 'C:\Backup\Chinook_Recovery_log.ldf',
     REPLACE;

-- Sorgu 4: Silinen verileri kurtarılan veritabanından geri yükle
-- Sonuç: GenreSayisi = 27, Jazz Fusion ve Ambient geri döndü
USE Chinook_Recovery;
SELECT * FROM Genre WHERE GenreId IN (26, 27);

INSERT INTO Chinook.dbo.Genre (GenreId, Name)
SELECT GenreId, Name FROM Chinook_Recovery.dbo.Genre
WHERE GenreId IN (26, 27);

USE Chinook;
SELECT COUNT(*) AS GenreSayisi FROM Genre;
SELECT * FROM Genre WHERE GenreId IN (26, 27);
