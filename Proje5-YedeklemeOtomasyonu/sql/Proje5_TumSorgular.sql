/* ============================================================
   BLM4522 - PROJE 7: VERİTABANI YEDEKLEME VE OTOMASYON ÇALIŞMASI
   Veritabanı: pubs  |  Platform: MS SQL Server (LocalDB)
   Ezgi SANKIR - 21290431
   ============================================================ */

/* ------------------------------------------------------------
   2. VERİTABANI TANITIMI
   ------------------------------------------------------------ */
USE pubs;

-- 2.1 Tablo yapısı
SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;

-- 2.2 Kayıt sayıları
SELECT 'authors' AS Tablo, COUNT(*) AS Kayit FROM authors UNION ALL
SELECT 'titles', COUNT(*) FROM titles UNION ALL
SELECT 'sales', COUNT(*) FROM sales UNION ALL
SELECT 'publishers', COUNT(*) FROM publishers UNION ALL
SELECT 'stores', COUNT(*) FROM stores UNION ALL
SELECT 'employee', COUNT(*) FROM employee
ORDER BY Kayit DESC;


/* ------------------------------------------------------------
   3. T-SQL OTOMATİK YEDEKLEME ALTYAPISI
   ------------------------------------------------------------ */
-- 3.1 Yedekleme log tablosu
USE pubs;
GO
CREATE TABLE dbo.YedeklemeLog (
    LogID         INT IDENTITY(1,1) PRIMARY KEY,
    VeritabaniAdi NVARCHAR(100),
    YedekTuru     NVARCHAR(20),
    DosyaYolu     NVARCHAR(500),
    BaslangicZamani DATETIME,
    BitisZamani     DATETIME,
    SureSaniye    AS DATEDIFF(SECOND, BaslangicZamani, BitisZamani),
    Durum         NVARCHAR(20),
    Mesaj         NVARCHAR(500)
);
GO

-- 3.2 Otomatik yedekleme prosedürü
CREATE OR ALTER PROCEDURE dbo.sp_OtomatikYedek
    @YedekTuru NVARCHAR(20) = 'FULL'   -- 'FULL' veya 'DIFF'
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @baslangic DATETIME = GETDATE();
    DECLARE @dosya NVARCHAR(500);
    DECLARE @tarih NVARCHAR(20) = FORMAT(GETDATE(), 'yyyyMMdd_HHmmss');

    SET @dosya = 'C:\Backup\pubs_' + @YedekTuru + '_' + @tarih + '.bak';

    BEGIN TRY
        IF @YedekTuru = 'FULL'
            BACKUP DATABASE pubs TO DISK = @dosya
            WITH FORMAT, NAME = 'pubs Otomatik Tam Yedek';
        ELSE
            BACKUP DATABASE pubs TO DISK = @dosya
            WITH DIFFERENTIAL, NAME = 'pubs Otomatik Diferansiyel Yedek';

        INSERT INTO dbo.YedeklemeLog (VeritabaniAdi, YedekTuru, DosyaYolu, BaslangicZamani, BitisZamani, Durum, Mesaj)
        VALUES ('pubs', @YedekTuru, @dosya, @baslangic, GETDATE(), 'BASARILI', 'Yedek basariyla alindi');

        PRINT 'Yedekleme başarılı: ' + @dosya;
    END TRY
    BEGIN CATCH
        INSERT INTO dbo.YedeklemeLog (VeritabaniAdi, YedekTuru, DosyaYolu, BaslangicZamani, BitisZamani, Durum, Mesaj)
        VALUES ('pubs', @YedekTuru, @dosya, @baslangic, GETDATE(), 'BASARISIZ', ERROR_MESSAGE());

        PRINT 'Yedekleme HATASI: ' + ERROR_MESSAGE();
    END CATCH
END;
GO


/* ------------------------------------------------------------
   4. PROSEDÜRÜ ÇALIŞTIRMA VE LOGLAMA
   ------------------------------------------------------------ */
EXEC dbo.sp_OtomatikYedek @YedekTuru = 'FULL';
EXEC dbo.sp_OtomatikYedek @YedekTuru = 'DIFF';
EXEC dbo.sp_OtomatikYedek @YedekTuru = 'FULL';

-- 4.4 Log kayıtlarını görüntüle
SELECT LogID, VeritabaniAdi, YedekTuru, DosyaYolu,
       BaslangicZamani, BitisZamani, SureSaniye, Durum, Mesaj
FROM dbo.YedeklemeLog
ORDER BY LogID;


/* ------------------------------------------------------------
   5. POWERSHELL İLE OTOMATİK YEDEKLEME
   ------------------------------------------------------------
   Bkz: powershell\OtomatikYedek.ps1
   Çalıştırma:
   powershell -ExecutionPolicy Bypass -File ".\OtomatikYedek.ps1"
   ------------------------------------------------------------ */
-- PowerShell yedeği sonrası log kontrolü
SELECT LogID, YedekTuru, DosyaYolu, BaslangicZamani, Durum, Mesaj
FROM pubs.dbo.YedeklemeLog
ORDER BY LogID;


/* ------------------------------------------------------------
   6. WINDOWS TASK SCHEDULER İLE ZAMANLAMA (PowerShell)
   ------------------------------------------------------------
   $action = New-ScheduledTaskAction -Execute "powershell.exe" `
       -Argument '-ExecutionPolicy Bypass -File "...\OtomatikYedek.ps1"'
   $trigger = New-ScheduledTaskTrigger -Daily -At 00:00
   Register-ScheduledTask -TaskName "pubs_OtomatikYedek" `
       -Action $action -Trigger $trigger -Force

   -- Manuel çalıştırma / doğrulama:
   Start-ScheduledTask -TaskName "pubs_OtomatikYedek"
   Get-ScheduledTaskInfo -TaskName "pubs_OtomatikYedek"
   ------------------------------------------------------------ */


/* ------------------------------------------------------------
   7. RAPORLAMA VE HATA UYARILARI
   ------------------------------------------------------------ */
-- 7.1 Yedekleme özet raporu
SELECT YedekTuru, COUNT(*) AS YedekSayisi,
    SUM(CASE WHEN Durum = 'BASARILI' THEN 1 ELSE 0 END) AS Basarili,
    SUM(CASE WHEN Durum = 'BASARISIZ' THEN 1 ELSE 0 END) AS Basarisiz,
    MAX(BaslangicZamani) AS SonYedekZamani
FROM dbo.YedeklemeLog
GROUP BY YedekTuru;

-- 7.2 Son yedek denetimi
SELECT MAX(BaslangicZamani) AS SonBasariliYedek,
    DATEDIFF(MINUTE, MAX(BaslangicZamani), GETDATE()) AS GecenDakika,
    CASE WHEN DATEDIFF(HOUR, MAX(BaslangicZamani), GETDATE()) > 24
         THEN 'UYARI: 24 saatten eski!' ELSE 'GÜNCEL' END AS YedekDurumu
FROM dbo.YedeklemeLog WHERE Durum = 'BASARILI';

-- 7.3 Hata uyarı prosedürü
GO
CREATE OR ALTER PROCEDURE dbo.sp_YedekUyariKontrol
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @basarisizSayi INT;
    SELECT @basarisizSayi = COUNT(*)
    FROM dbo.YedeklemeLog
    WHERE Durum = 'BASARISIZ' AND BaslangicZamani >= DATEADD(DAY, -1, GETDATE());

    IF @basarisizSayi > 0
        SELECT 'UYARI' AS Seviye,
               CONCAT(@basarisizSayi, ' adet basarisiz yedekleme tespit edildi! Yonetici bilgilendirilmeli.') AS Mesaj;
    ELSE
        SELECT 'BILGI' AS Seviye,
               'Son 24 saatte basarisiz yedekleme yok. Sistem saglikli.' AS Mesaj;
END;
GO
EXEC dbo.sp_YedekUyariKontrol;

-- 7.4 Hata senaryosu simülasyonu
DECLARE @sahteDosya NVARCHAR(500) = 'Z:\OlmayanKlasor\pubs_hata.bak';
BEGIN TRY
    BACKUP DATABASE pubs TO DISK = @sahteDosya;
END TRY
BEGIN CATCH
    INSERT INTO dbo.YedeklemeLog (VeritabaniAdi, YedekTuru, DosyaYolu, BaslangicZamani, BitisZamani, Durum, Mesaj)
    VALUES ('pubs', 'FULL', @sahteDosya, GETDATE(), GETDATE(), 'BASARISIZ', ERROR_MESSAGE());
END CATCH;

EXEC dbo.sp_YedekUyariKontrol;  -- artık UYARI döner
